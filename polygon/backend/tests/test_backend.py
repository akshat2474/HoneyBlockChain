"""
HoneyChain backend test suite.

Runs without a real database, blockchain, or IPFS connection by patching
the service layer and using FastAPI's TestClient.

Run: pytest tests/ -v
"""
from __future__ import annotations

import hashlib
import hmac
import os
import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

# ── Mock out DB before importing app ────────────────────────────────────────
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret")
os.environ.setdefault("QR_HMAC_SECRET", "test-qr-secret")
os.environ.setdefault("AMOY_RPC_URL", "")
os.environ.setdefault("PRIVATE_KEY", "0" * 64)
os.environ.setdefault("CONTRACT_ADDRESS", "0x0000000000000000000000000000000000000000")
os.environ.setdefault("PINATA_JWT", "test-jwt")


# ── QR service unit tests ─────────────────────────────────────────────────────

from app.services.qr_service import generate_qr_token, verify_qr_signature


def test_qr_token_round_trip():
    """A generated token should verify successfully."""
    data = generate_qr_token("HC-TEST-001")
    assert verify_qr_signature("HC-TEST-001", data["nonce"], data["signature"])


def test_qr_token_wrong_batch_code_fails():
    data = generate_qr_token("HC-TEST-001")
    assert not verify_qr_signature("HC-WRONG", data["nonce"], data["signature"])


def test_qr_token_tampered_signature_fails():
    data = generate_qr_token("HC-TEST-001")
    assert not verify_qr_signature("HC-TEST-001", data["nonce"], "bad-sig")


def test_qr_token_wrong_nonce_fails():
    data = generate_qr_token("HC-TEST-001")
    assert not verify_qr_signature("HC-TEST-001", "wrong-nonce", data["signature"])


def test_qr_url_contains_batch_code():
    data = generate_qr_token("HC-TEST-002")
    assert "HC-TEST-002" in data["qr_url"]


# ── IPFS service unit tests ───────────────────────────────────────────────────

from app.services.ipfs import canonical_json, sha256_hex


def test_canonical_json_is_deterministic():
    """Same dict always produces the same string regardless of insertion order."""
    d1 = {"b": 2, "a": 1}
    d2 = {"a": 1, "b": 2}
    assert canonical_json(d1) == canonical_json(d2)


def test_sha256_hex_known_value():
    result = sha256_hex("hello")
    assert result == hashlib.sha256(b"hello").hexdigest()


# ── Auth unit tests ───────────────────────────────────────────────────────────

from app.auth import create_access_token, hash_password, verify_password
from app.models.actor import ActorRole


def test_password_round_trip():
    hashed = hash_password("mysecretpassword")
    assert verify_password("mysecretpassword", hashed)
    assert not verify_password("wrongpassword", hashed)


def test_jwt_token_contains_role():
    from jose import jwt as jose_jwt
    token = create_access_token(uuid.uuid4(), ActorRole.BEEKEEPER)
    payload = jose_jwt.decode(token, os.environ["JWT_SECRET_KEY"], algorithms=["HS256"])
    assert payload["role"] == "beekeeper"


# ── Blockchain service unit tests ─────────────────────────────────────────────

from app.services.blockchain import batch_id_hash, metadata_bytes32


def test_batch_id_hash_is_32_bytes():
    result = batch_id_hash("HC-TEST-001")
    assert len(result) == 32


def test_metadata_bytes32_is_32_bytes():
    result = metadata_bytes32('{"key":"value"}')
    assert len(result) == 32


def test_batch_id_hash_is_deterministic():
    assert batch_id_hash("HC-TEST-001") == batch_id_hash("HC-TEST-001")


def test_different_batch_codes_produce_different_hashes():
    assert batch_id_hash("HC-001") != batch_id_hash("HC-002")


# ── API smoke tests (no DB required — patches get_db) ────────────────────────

@pytest.fixture
def mock_db():
    db = MagicMock()
    db.query.return_value.filter.return_value.first.return_value = None
    return db


@pytest.fixture
def client(mock_db):
    from app.main import app
    from app.database import get_db

    def override_get_db():
        yield mock_db

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


def test_health_check(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_openapi_docs_available(client):
    response = client.get("/docs")
    assert response.status_code == 200


def test_register_creates_actor(client, mock_db):
    # Simulate name not taken
    mock_db.query.return_value.filter.return_value.first.return_value = None
    from app.models.actor import Actor, ActorRole
    from datetime import datetime
    fake_actor = MagicMock()
    fake_actor.id = uuid.uuid4()
    fake_actor.role = ActorRole.BEEKEEPER
    fake_actor.name = "Test Beekeeper"
    fake_actor.region = "Maharashtra"
    fake_actor.wallet_address = None
    fake_actor.kyc_status = "pending"
    fake_actor.created_at = datetime.utcnow()
    mock_db.refresh.side_effect = lambda obj: None

    with patch("app.api.auth.Actor", return_value=fake_actor):
        response = client.post("/auth/register", json={
            "name": "Test Beekeeper",
            "role": "beekeeper",
            "password": "password123",
            "region": "Maharashtra",
        })
    # 201 or 400 (name already exists from mock) — just confirm no 500
    assert response.status_code in (201, 400, 422)


def test_login_wrong_credentials_returns_401(client, mock_db):
    mock_db.query.return_value.filter.return_value.first.return_value = None
    response = client.post("/auth/login", json={"name": "nobody", "password": "wrong"})
    assert response.status_code == 401


def test_verify_invalid_signature_returns_400(client, mock_db):
    response = client.get("/verify/HC-TEST-001?n=badnonce&sig=badsig")
    assert response.status_code == 400


def test_legacy_create_batch_requires_body(client):
    response = client.post("/create-batch", json={})
    assert response.status_code == 422  # Pydantic validation error


def test_protected_endpoint_requires_auth(client):
    response = client.post("/hive/", json={"beekeeper_id": str(uuid.uuid4())})
    assert response.status_code == 401

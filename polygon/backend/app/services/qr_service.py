"""QR signing and verification using HMAC-SHA256."""
from __future__ import annotations

import hashlib
import hmac
import os
import secrets
import uuid

from dotenv import load_dotenv

load_dotenv()

_SECRET = os.getenv("QR_HMAC_SECRET", "change-me-in-production").encode()
BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "http://localhost:8000")


def _sign(batch_code: str, nonce: str) -> str:
    """HMAC-SHA256 over 'batch_code:nonce'."""
    message = f"{batch_code}:{nonce}".encode()
    return hmac.new(_SECRET, message, hashlib.sha256).hexdigest()


def generate_qr_token(batch_code: str) -> dict:
    """
    Generate a signed QR payload.

    Returns a dict with:
    - nonce (raw, include in QR URL)
    - nonce_hash (store in DB, never expose raw nonce separately)
    - signature (include in QR URL)
    - qr_url (the full URL to embed in the QR code)
    """
    nonce = secrets.token_urlsafe(16)
    sig = _sign(batch_code, nonce)
    nonce_hash = hashlib.sha256(nonce.encode()).hexdigest()
    qr_url = f"{BACKEND_BASE_URL}/verify/{batch_code}?n={nonce}&sig={sig}"
    return {
        "nonce": nonce,
        "nonce_hash": nonce_hash,
        "signature": sig,
        "qr_url": qr_url,
    }


def verify_qr_signature(batch_code: str, nonce: str, signature: str) -> bool:
    """Constant-time comparison to prevent timing attacks."""
    expected = _sign(batch_code, nonce)
    return hmac.compare_digest(expected, signature)

"""Public consumer verification endpoint — the QR scan destination."""
from __future__ import annotations

import hashlib
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.batch import Batch, BatchStatus
from app.models.qr import QrScan, QrToken
from app.schemas.verify import BlockchainProof, IpfsProof, VerifyResponse
from app.services import blockchain, ipfs, qr_service

router = APIRouter(tags=["verify"])

EXPLORER_BASE = "https://amoy.polygonscan.com/tx/"


def _get_active_qr_token(db: Session, batch: Batch) -> QrToken | None:
    return (
        db.query(QrToken)
        .filter(QrToken.batch_id == batch.id, QrToken.active == True)  # noqa: E712
        .order_by(QrToken.created_at.desc())
        .first()
    )


def _log_scan(db: Session, token: QrToken, request: Request, status: str) -> None:
    scan = QrScan(
        qr_token_id=token.id,
        scanned_at=datetime.now(timezone.utc),
        ip_region=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
        status=status,
    )
    token.scan_count += 1
    db.add(scan)
    db.commit()


def _build_blockchain_proof(batch: Batch, on_chain: dict | None) -> BlockchainProof:
    if not on_chain:
        return BlockchainProof(
            contract_address=batch.contract_address or "",
            transaction_hash=batch.create_tx_hash,
            block_explorer_url=f"{EXPLORER_BASE}{batch.create_tx_hash}" if batch.create_tx_hash else None,
            batch_hash_on_chain=None,
            metadata_cid=batch.metadata_cid,
            metadata_hash_on_chain=None,
            lab_verified=False,
            recalled=False,
        )
    return BlockchainProof(
        contract_address=batch.contract_address or "",
        transaction_hash=batch.create_tx_hash,
        block_explorer_url=f"{EXPLORER_BASE}{batch.create_tx_hash}" if batch.create_tx_hash else None,
        batch_hash_on_chain=on_chain.get("batchIdHash"),
        metadata_cid=on_chain.get("metadataCID"),
        metadata_hash_on_chain=on_chain.get("metadataHash"),
        lab_verified=on_chain.get("labVerified", False),
        recalled=on_chain.get("recalled", False),
    )


def _build_ipfs_proof(batch: Batch, on_chain: dict | None) -> IpfsProof:
    if not batch.metadata_cid:
        return IpfsProof(cid=None, gateway_url=None, hash_matches=None)

    expected_hash = None
    if on_chain:
        expected_hash = on_chain.get("metadataHash")

    hash_matches = None
    if expected_hash:
        hash_matches = ipfs.fetch_and_verify(batch.metadata_cid, expected_hash)

    return IpfsProof(
        cid=batch.metadata_cid,
        gateway_url=ipfs.gateway_url(batch.metadata_cid),
        hash_matches=hash_matches,
    )


@router.get("/verify/{batch_code}", response_model=VerifyResponse)
def verify_batch(
    batch_code: str,
    request: Request,
    n: str = Query(..., description="Nonce from QR URL"),
    sig: str = Query(..., description="HMAC signature from QR URL"),
    db: Session = Depends(get_db),
):
    """
    Public consumer verification endpoint.

    Validates the QR signature, then fetches live data from:
    - PostgreSQL (operational record)
    - Polygon smart contract (on-chain proof)
    - IPFS (metadata integrity check)
    """
    if not qr_service.verify_qr_signature(batch_code, n, sig):
        raise HTTPException(status_code=400, detail="Invalid QR signature — this QR may be forged")

    batch = db.query(Batch).filter(Batch.batch_code == batch_code).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")

    token = _get_active_qr_token(db, batch)
    if not token:
        raise HTTPException(status_code=404, detail="QR token not found")

    duplicate_warning = token.scan_count >= 5
    scan_status = "duplicate_warning" if duplicate_warning else "ok"
    _log_scan(db, token, request, scan_status)

    on_chain = blockchain.get_batch_on_chain(batch_code)

    is_recalled = (
        batch.status == BatchStatus.RECALLED
        or (on_chain and on_chain.get("recalled", False))
    )

    bk_actor = None
    if batch.harvest and batch.harvest.hive and batch.harvest.hive.beekeeper:
        bk_actor = batch.harvest.hive.beekeeper.actor

    mismatches = []
    if on_chain:
        _STATUS_INDEX = {s: i for i, s in enumerate(BatchStatus)}
        if on_chain.get("status") != _STATUS_INDEX.get(batch.status, on_chain.get("status")):
            mismatches.append("status")
        if on_chain.get("recalled") != (batch.status == BatchStatus.RECALLED):
            mismatches.append("recalled")
        if bk_actor and bk_actor.wallet_address and on_chain.get("beekeeper") and on_chain.get("beekeeper").lower() != bk_actor.wallet_address.lower():
            mismatches.append("beekeeper")

    return VerifyResponse(
        batch_code=batch_code,
        status="RECALLED" if is_recalled else batch.status.value,
        beekeeper_name=bk_actor.name if bk_actor else None,
        region=bk_actor.region if bk_actor else None,
        harvest_date=batch.harvest.harvest_date.isoformat() if batch.harvest else None,
        quantity_g=batch.harvest.quantity_g if batch.harvest else None,
        honey_type=None,  # stored in IPFS metadata
        blockchain=_build_blockchain_proof(batch, on_chain),
        ipfs=_build_ipfs_proof(batch, on_chain),
        scan_count=token.scan_count,
        duplicate_warning=duplicate_warning,
        mismatches=mismatches if mismatches else None
    )

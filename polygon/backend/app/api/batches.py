"""Batches router — harvest, batch creation, lab verification, custody transfer, recall."""
from __future__ import annotations

import json
import os
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, File, Form, UploadFile
from sqlalchemy.orm import Session

from app.auth import get_current_actor, require_role
from app.database import get_db
from app.models.actor import Actor, ActorRole
from app.models.batch import Batch, BatchStatus, Certificate, CustodyEvent, Harvest
from app.models.qr import QrToken
from app.schemas.batch import (
    BatchCreateRequest,
    BatchResponse,
    CustodyTransferRequest,
    CustodyTransferResponse,
    HarvestCreateRequest,
    HarvestResponse,
    LabVerifyRequest,
    LabVerifyResponse,
    RecallRequest,
)
from app.services import blockchain, ipfs, qr_service

router = APIRouter(tags=["batches"])

CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS", "")

# ---------- Status → on-chain index map (mirrors BatchStatus enum order) ----------
_STATUS_INDEX = {s: i for i, s in enumerate(BatchStatus)}


# ============================================================
# Harvests
# ============================================================

@router.post("/harvest", response_model=HarvestResponse, status_code=status.HTTP_201_CREATED)
def create_harvest(
    req: HarvestCreateRequest,
    db: Session = Depends(get_db),
    actor: Actor = Depends(require_role(ActorRole.BEEKEEPER)),
):
    """Record a physical honey harvest event."""
    harvest = Harvest(
        hive_id=req.hive_id,
        harvest_date=req.harvest_date,
        quantity_g=req.quantity_g,
        floral_source=req.floral_source,
        notes=req.notes,
    )
    db.add(harvest)
    db.commit()
    db.refresh(harvest)
    return harvest


@router.get("/harvest/{harvest_id}", response_model=HarvestResponse)
def get_harvest(
    harvest_id: uuid.UUID,
    db: Session = Depends(get_db),
    _actor: Actor = Depends(get_current_actor),
):
    harvest = db.query(Harvest).filter(Harvest.id == harvest_id).first()
    if not harvest:
        raise HTTPException(status_code=404, detail="Harvest not found")
    return harvest


# ============================================================
# Batches
# ============================================================

def _build_metadata(req: BatchCreateRequest, harvest: Harvest, actor: Actor) -> dict:
    return {
        "batchCode": req.batch_code,
        "honeyType": req.honey_type,
        "region": req.region or actor.region,
        "beekeeperPublicName": actor.name,
        "harvestDate": harvest.harvest_date.isoformat(),
        "quantityGrams": harvest.quantity_g,
        "floralSource": harvest.floral_source,
        "createdAt": datetime.utcnow().isoformat(),
    }


@router.post("/batch", response_model=BatchResponse, status_code=status.HTTP_201_CREATED)
def create_batch(
    req: BatchCreateRequest,
    db: Session = Depends(get_db),
    actor: Actor = Depends(require_role(ActorRole.BEEKEEPER)),
):
    """
    Create a honey batch:
    1. Build metadata JSON
    2. Upload to IPFS (Pinata)
    3. Submit createBatch tx to Polygon
    4. Persist to DB
    5. Generate signed QR token
    """
    existing = db.query(Batch).filter(Batch.batch_code == req.batch_code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Batch code already exists")

    harvest = db.query(Harvest).filter(Harvest.id == req.harvest_id).first()
    if not harvest:
        raise HTTPException(status_code=404, detail="Harvest not found")

    metadata = _build_metadata(req, harvest, actor)
    metadata_str = json.dumps(metadata, sort_keys=True)

    try:
        cid, meta_hash = ipfs.upload_json(metadata)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"IPFS upload failed: {exc}")

    try:
        tx_hash = blockchain.create_batch_tx(
            batch_code=req.batch_code,
            quantity_grams=harvest.quantity_g,
            harvest_timestamp=int(harvest.harvest_date.timestamp()),
            metadata_cid=cid,
            metadata_json_str=metadata_str,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Blockchain tx failed: {exc}")

    batch_hash_hex = blockchain.batch_id_hash(req.batch_code).hex()

    batch = Batch(
        batch_code=req.batch_code,
        batch_hash=batch_hash_hex,
        harvest_id=harvest.id,
        status=BatchStatus.CREATED,
        metadata_cid=cid,
        metadata_hash=meta_hash,
        contract_address=CONTRACT_ADDRESS,
        create_tx_hash=tx_hash,
        current_custodian_id=actor.id,
    )
    db.add(batch)
    db.flush()

    qr_data = qr_service.generate_qr_token(req.batch_code)
    qr_token = QrToken(
        batch_id=batch.id,
        nonce_hash=qr_data["nonce_hash"],
        signature=qr_data["signature"],
    )
    db.add(qr_token)
    db.commit()
    db.refresh(batch)

    response = BatchResponse.model_validate(batch)
    response.qr_url = qr_data["qr_url"]
    return response


@router.get("/batch/{batch_id}", response_model=BatchResponse)
def get_batch(
    batch_id: uuid.UUID,
    db: Session = Depends(get_db),
    _actor: Actor = Depends(get_current_actor),
):
    batch = db.query(Batch).filter(Batch.id == batch_id).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")
    return batch


@router.get("/batch/code/{batch_code}", response_model=BatchResponse)
def get_batch_by_code(
    batch_code: str,
    db: Session = Depends(get_db),
    _actor: Actor = Depends(get_current_actor),
):
    """Look up a batch by its human-readable batch code (e.g. HC-2026-CL01-000123)."""
    batch = db.query(Batch).filter(Batch.batch_code == batch_code).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")
    return batch


# ============================================================
# Lab verification
# ============================================================

@router.post("/lab-verification", response_model=LabVerifyResponse, status_code=status.HTTP_201_CREATED)
async def lab_verification(
    batch_id: uuid.UUID = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    actor: Actor = Depends(require_role(ActorRole.LAB)),
):
    """
    Upload a lab certificate, hash it, pin to IPFS, and record on-chain.
    """
    batch = db.query(Batch).filter(Batch.id == batch_id).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")

    file_bytes = await file.read()
    
    try:
        certificate_cid, file_hash_hex = ipfs.upload_file(file_bytes, file.filename)
        certificate_hash_0x = "0x" + file_hash_hex
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"IPFS pinning failed: {exc}")

    metadata = {"labVerification": True, "certificateHash": certificate_hash_0x, "cid": certificate_cid}
    metadata_str = json.dumps(metadata, sort_keys=True)

    try:
        tx_hash = blockchain.verify_lab_tx(
            batch_code=batch.batch_code,
            lab_report_hash_hex=certificate_hash_0x,
            metadata_cid=certificate_cid,
            metadata_json_str=metadata_str,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Blockchain tx failed: {exc}")

    cert = Certificate(
        batch_id=batch.id,
        lab_actor_id=actor.id,
        certificate_hash=certificate_hash_0x,
        cid=certificate_cid,
        tx_hash=tx_hash,
    )
    db.add(cert)

    batch.status = BatchStatus.LAB_VERIFIED
    db.commit()
    db.refresh(cert)

    return LabVerifyResponse(batch_id=batch.id, tx_hash=tx_hash, certificate_id=cert.id)


# ============================================================
# Custody transfer
# ============================================================

@router.post("/batch/{batch_id}/transfer", response_model=CustodyTransferResponse)
def transfer_custody(
    batch_id: uuid.UUID,
    req: CustodyTransferRequest,
    db: Session = Depends(get_db),
    actor: Actor = Depends(get_current_actor),
):
    """Transfer custody of a batch to another actor and advance its status."""
    batch = db.query(Batch).filter(Batch.id == batch_id).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")

    if str(batch.current_custodian_id) != str(actor.id):
        raise HTTPException(status_code=403, detail="Only the current custodian can transfer")

    to_actor = db.query(Actor).filter(Actor.id == req.to_actor_id).first()
    if not to_actor:
        raise HTTPException(status_code=404, detail="Target actor not found")

    if not to_actor.wallet_address:
        raise HTTPException(status_code=400, detail="Target actor has no wallet address")

    next_status_index = _STATUS_INDEX[req.next_status]

    try:
        tx_hash = blockchain.transfer_custody_tx(
            batch_code=batch.batch_code,
            to_address=to_actor.wallet_address,
            next_status_index=next_status_index,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Blockchain tx failed: {exc}")

    event = CustodyEvent(
        batch_id=batch.id,
        from_actor_id=actor.id,
        to_actor_id=req.to_actor_id,
        stage=req.next_status.value,
        tx_hash=tx_hash,
    )
    db.add(event)

    batch.current_custodian_id = req.to_actor_id
    batch.status = req.next_status
    db.commit()

    return CustodyTransferResponse(
        batch_id=batch.id, tx_hash=tx_hash, new_status=req.next_status
    )


# ============================================================
# Recall
# ============================================================

@router.post("/batch/{batch_id}/recall", status_code=status.HTTP_200_OK)
def recall_batch(
    batch_id: uuid.UUID,
    req: RecallRequest,
    db: Session = Depends(get_db),
    _actor: Actor = Depends(require_role(ActorRole.ADMIN)),
):
    """Admin-only: recall a batch and record the reason on-chain."""
    batch = db.query(Batch).filter(Batch.id == batch_id).first()
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")

    reason_cid = req.reason_cid or ""

    try:
        tx_hash = blockchain.recall_batch_tx(batch.batch_code, reason_cid)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Blockchain tx failed: {exc}")

    batch.status = BatchStatus.RECALLED
    db.commit()

    return {"batch_id": str(batch_id), "tx_hash": tx_hash, "status": "Recalled"}

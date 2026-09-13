"""Pydantic schemas for harvests, batches, lab verification, and custody transfers."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.models.batch import BatchStatus


# ---------- Harvest ----------

class HarvestCreateRequest(BaseModel):
    hive_id: uuid.UUID
    harvest_date: datetime
    quantity_g: int
    floral_source: Optional[str] = None
    notes: Optional[str] = None


class HarvestResponse(BaseModel):
    id: uuid.UUID
    hive_id: uuid.UUID
    harvest_date: datetime
    quantity_g: int
    floral_source: Optional[str]
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


# ---------- Batch ----------

class BatchCreateRequest(BaseModel):
    batch_code: str
    harvest_id: uuid.UUID
    honey_type: Optional[str] = None
    region: Optional[str] = None


class BatchResponse(BaseModel):
    id: uuid.UUID
    batch_code: str
    batch_hash: str
    status: BatchStatus
    metadata_cid: Optional[str]
    metadata_hash: Optional[str]
    contract_address: Optional[str]
    create_tx_hash: Optional[str]
    created_at: datetime
    qr_url: Optional[str] = None

    model_config = {"from_attributes": True}


# ---------- Lab verification ----------

class LabVerifyRequest(BaseModel):
    batch_id: uuid.UUID
    certificate_hash: str   # 0x-prefixed hex SHA-256 of the lab certificate PDF
    certificate_cid: Optional[str] = None  # IPFS CID if cert was uploaded


class LabVerifyResponse(BaseModel):
    batch_id: uuid.UUID
    tx_hash: str
    certificate_id: uuid.UUID

    model_config = {"from_attributes": True}


# ---------- Custody transfer ----------

class CustodyTransferRequest(BaseModel):
    to_actor_id: uuid.UUID
    next_status: BatchStatus


class CustodyTransferResponse(BaseModel):
    batch_id: uuid.UUID
    tx_hash: str
    new_status: BatchStatus

    model_config = {"from_attributes": True}


# ---------- Recall ----------

class RecallRequest(BaseModel):
    reason: str
    reason_cid: Optional[str] = None

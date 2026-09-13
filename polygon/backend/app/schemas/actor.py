"""Pydantic schemas for actor registration, login, and responses."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr

from app.models.actor import ActorRole


# ---------- Request bodies ----------

class ActorRegisterRequest(BaseModel):
    name: str
    role: ActorRole
    region: Optional[str] = None
    wallet_address: Optional[str] = None
    password: str
    # Beekeeper-specific (optional)
    cooperative_id: Optional[str] = None
    village: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None


class LoginRequest(BaseModel):
    name: str
    password: str


# ---------- Responses ----------

class ActorResponse(BaseModel):
    id: uuid.UUID
    role: ActorRole
    name: str
    region: Optional[str]
    wallet_address: Optional[str]
    kyc_status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    actor_id: uuid.UUID
    role: ActorRole

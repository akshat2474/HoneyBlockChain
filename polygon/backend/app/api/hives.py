"""Hives router — hive registration, sensor data ingestion, and telemetry reads."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.auth import get_current_actor, require_role
from app.database import get_db
from app.models.actor import Actor, ActorRole
from app.models.hive import Hive, SensorReading
from app.schemas.hive import (
    HiveCreateRequest,
    HiveResponse,
    SensorDataRequest,
    SensorDataResponse,
)

router = APIRouter(prefix="/hive", tags=["hives"])


def _encrypt_gps(lat: Optional[float], lon: Optional[float]) -> Optional[str]:
    """Placeholder GPS encryption. Replace with Fernet or AES-GCM in production."""
    if lat is None or lon is None:
        return None
    return f"enc:{lat:.6f},{lon:.6f}"  # TODO: real encryption before production


@router.post("/", response_model=HiveResponse, status_code=status.HTTP_201_CREATED)
def create_hive(
    req: HiveCreateRequest,
    db: Session = Depends(get_db),
    actor: Actor = Depends(require_role(ActorRole.BEEKEEPER, ActorRole.ADMIN)),
):
    """Register a new hive for a beekeeper."""
    hive = Hive(
        beekeeper_id=req.beekeeper_id,
        device_id=req.device_id,
        region_public=req.region_public,
        gps_encrypted=_encrypt_gps(req.gps_lat, req.gps_lon),
    )
    db.add(hive)
    db.commit()
    db.refresh(hive)
    return hive


@router.get("/{hive_id}", response_model=HiveResponse)
def get_hive(
    hive_id: uuid.UUID,
    db: Session = Depends(get_db),
    _actor: Actor = Depends(get_current_actor),
):
    hive = db.query(Hive).filter(Hive.id == hive_id).first()
    if not hive:
        raise HTTPException(status_code=404, detail="Hive not found")
    return hive


@router.post("/sensor-data", response_model=SensorDataResponse, status_code=status.HTTP_201_CREATED)
def ingest_sensor_data(
    req: SensorDataRequest,
    db: Session = Depends(get_db),
    _actor: Actor = Depends(get_current_actor),
):
    """
    Manual API ingestion of sensor readings (supplements MQTT).
    The MQTT subscriber handles real-time ESP32 payloads automatically.
    """
    hive = db.query(Hive).filter(Hive.id == req.hive_id).first()
    if not hive:
        raise HTTPException(status_code=404, detail="Hive not found")

    reading = SensorReading(
        hive_id=req.hive_id,
        ts=req.ts,
        temperature_c=req.temperature_c,
        humidity_pct=req.humidity_pct,
        pressure_hpa=req.pressure_hpa,
        weight_kg=req.weight_kg,
        battery_pct=req.battery_pct,
        source=req.source,
        is_simulated=req.is_simulated,
    )
    db.add(reading)
    db.commit()
    db.refresh(reading)
    return reading


@router.get("/{hive_id}/sensor-data", response_model=List[SensorDataResponse])
def get_sensor_data(
    hive_id: uuid.UUID,
    limit: int = Query(50, le=200),
    db: Session = Depends(get_db),
    _actor: Actor = Depends(get_current_actor),
):
    """Retrieve the most recent sensor readings for a hive (newest first)."""
    readings = (
        db.query(SensorReading)
        .filter(SensorReading.hive_id == hive_id)
        .order_by(SensorReading.ts.desc())
        .limit(limit)
        .all()
    )
    return readings

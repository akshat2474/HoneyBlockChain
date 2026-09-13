"""Pydantic schemas for hives and sensor readings."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel


# ---------- Hive ----------

class HiveCreateRequest(BaseModel):
    beekeeper_id: uuid.UUID
    device_id: Optional[str] = None
    region_public: Optional[str] = None
    gps_lat: Optional[float] = None   # stored encrypted; not persisted raw
    gps_lon: Optional[float] = None


class HiveResponse(BaseModel):
    id: uuid.UUID
    beekeeper_id: uuid.UUID
    device_id: Optional[str]
    region_public: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


# ---------- Sensor data ----------

class SensorDataRequest(BaseModel):
    hive_id: uuid.UUID
    ts: datetime
    temperature_c: Optional[float] = None
    humidity_pct: Optional[float] = None
    pressure_hpa: Optional[float] = None
    weight_kg: Optional[float] = None
    battery_pct: Optional[float] = None
    source: str = "api"
    is_simulated: bool = False


class SensorDataResponse(BaseModel):
    id: uuid.UUID
    hive_id: uuid.UUID
    ts: datetime
    temperature_c: Optional[float]
    humidity_pct: Optional[float]
    pressure_hpa: Optional[float]
    weight_kg: Optional[float]
    battery_pct: Optional[float]
    source: str
    is_simulated: bool

    model_config = {"from_attributes": True}

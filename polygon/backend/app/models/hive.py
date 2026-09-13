"""SQLAlchemy ORM models for hives and sensor readings."""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class Hive(Base):
    __tablename__ = "hives"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    beekeeper_id = Column(
        UUID(as_uuid=True), ForeignKey("beekeepers.actor_id"), nullable=False
    )
    device_id = Column(String)
    region_public = Column(String)
    gps_encrypted = Column(String)  # encrypted GPS; raw coordinates never stored plain
    created_at = Column(DateTime, default=datetime.utcnow)

    beekeeper = relationship("Beekeeper", back_populates="hives")
    sensor_readings = relationship("SensorReading", back_populates="hive")
    harvests = relationship("Harvest", back_populates="hive")
    ai_inferences = relationship("AiInference", back_populates="hive")


class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    hive_id = Column(UUID(as_uuid=True), ForeignKey("hives.id"), nullable=False)
    ts = Column(DateTime, nullable=False, index=True)
    temperature_c = Column(Float)
    humidity_pct = Column(Float)
    pressure_hpa = Column(Float)
    weight_kg = Column(Float)
    battery_pct = Column(Float)
    source = Column(String, default="mqtt")  # mqtt | api | simulated
    is_simulated = Column(Boolean, default=False)

    hive = relationship("Hive", back_populates="sensor_readings")

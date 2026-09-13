"""SQLAlchemy ORM models for harvests, batches, certificates, custody, and AI inferences."""
import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum as SAEnum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class BatchStatus(str, enum.Enum):
    CREATED = "Created"
    HARVESTED = "Harvested"
    PROCESSED = "Processed"
    LAB_VERIFIED = "LabVerified"
    PACKAGED = "Packaged"
    IN_DISTRIBUTION = "InDistribution"
    AT_RETAIL = "AtRetail"
    SOLD = "Sold"
    RECALLED = "Recalled"
    REJECTED = "Rejected"


class Harvest(Base):
    __tablename__ = "harvests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    hive_id = Column(UUID(as_uuid=True), ForeignKey("hives.id"), nullable=False)
    harvest_date = Column(DateTime, nullable=False)
    quantity_g = Column(Integer, nullable=False)
    floral_source = Column(String)
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    hive = relationship("Hive", back_populates="harvests")
    batches = relationship("Batch", back_populates="harvest")


class Batch(Base):
    __tablename__ = "batches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_code = Column(String, unique=True, nullable=False)
    batch_hash = Column(String, nullable=False)  # keccak256 hex of batch_code
    harvest_id = Column(UUID(as_uuid=True), ForeignKey("harvests.id"))
    status = Column(SAEnum(BatchStatus, values_callable=lambda obj: [e.value for e in obj]), default=BatchStatus.CREATED)
    metadata_cid = Column(String)
    metadata_hash = Column(String)
    contract_address = Column(String)
    create_tx_hash = Column(String)
    current_custodian_id = Column(UUID(as_uuid=True), ForeignKey("actors.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

    harvest = relationship("Harvest", back_populates="batches")
    certificates = relationship("Certificate", back_populates="batch")
    custody_events = relationship("CustodyEvent", back_populates="batch")
    qr_tokens = relationship("QrToken", back_populates="batch")
    ai_inferences = relationship("AiInference", back_populates="batch")


class Certificate(Base):
    __tablename__ = "certificates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_id = Column(UUID(as_uuid=True), ForeignKey("batches.id"), nullable=False)
    lab_actor_id = Column(UUID(as_uuid=True), ForeignKey("actors.id"), nullable=False)
    certificate_hash = Column(String, nullable=False)
    cid = Column(String)
    tx_hash = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

    batch = relationship("Batch", back_populates="certificates")


class CustodyEvent(Base):
    __tablename__ = "custody_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_id = Column(UUID(as_uuid=True), ForeignKey("batches.id"), nullable=False)
    from_actor_id = Column(UUID(as_uuid=True), ForeignKey("actors.id"))
    to_actor_id = Column(UUID(as_uuid=True), ForeignKey("actors.id"), nullable=False)
    stage = Column(String, nullable=False)
    tx_hash = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

    batch = relationship("Batch", back_populates="custody_events")
    from_actor = relationship(
        "Actor", foreign_keys=[from_actor_id], back_populates="from_custody_events"
    )
    to_actor = relationship(
        "Actor", foreign_keys=[to_actor_id], back_populates="to_custody_events"
    )


class AiInference(Base):
    __tablename__ = "ai_inferences"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    hive_id = Column(UUID(as_uuid=True), ForeignKey("hives.id"))
    batch_id = Column(UUID(as_uuid=True), ForeignKey("batches.id"))
    model_version = Column(String, nullable=False)
    input_hash = Column(String, nullable=False)  # SHA-256 of the uploaded image bytes
    prediction = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    hive = relationship("Hive", back_populates="ai_inferences")
    batch = relationship("Batch", back_populates="ai_inferences")

"""SQLAlchemy ORM models for QR tokens and scan analytics."""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class QrToken(Base):
    __tablename__ = "qr_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    batch_id = Column(UUID(as_uuid=True), ForeignKey("batches.id"), nullable=False)
    nonce_hash = Column(String, nullable=False)   # SHA-256 of the raw nonce
    signature = Column(String, nullable=False)    # HMAC-SHA256 of (batch_code + nonce)
    active = Column(Boolean, default=True)
    scan_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    batch = relationship("Batch", back_populates="qr_tokens")
    scans = relationship("QrScan", back_populates="qr_token")


class QrScan(Base):
    __tablename__ = "qr_scans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    qr_token_id = Column(
        UUID(as_uuid=True), ForeignKey("qr_tokens.id"), nullable=False
    )
    scanned_at = Column(DateTime, default=datetime.utcnow)
    ip_region = Column(String)
    user_agent = Column(String)
    status = Column(String, default="ok")  # ok | duplicate_warning | invalid

    qr_token = relationship("QrToken", back_populates="scans")

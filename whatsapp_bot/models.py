import uuid
from sqlalchemy import Column, String, Integer, Boolean, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

def generate_uuid():
    return str(uuid.uuid4())

class Beekeeper(Base):
    __tablename__ = "beekeepers"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    wallet_address = Column(String, unique=True, nullable=True)
    name = Column(String, nullable=False)
    phone = Column(String, unique=True, nullable=False)
    email = Column(String, nullable=True)
    region = Column(String, nullable=False)
    kvic_id = Column(String, unique=True, nullable=True)
    
    # Capacity & Practice fields
    beekeeper_type = Column(String, nullable=True)
    hives_count = Column(Integer, default=0)
    yards_count = Column(Integer, default=0)
    practices = Column(String, nullable=True)

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    batches = relationship("HoneyBatch", back_populates="beekeeper")
    whatsapp_users = relationship("WhatsAppUser", back_populates="beekeeper")

class HoneyBatch(Base):
    __tablename__ = "honey_batches"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    batch_id_hash = Column(String, unique=True, nullable=False)
    beekeeper_id = Column(String, ForeignKey("beekeepers.id"))
    quantity_grams = Column(Integer, nullable=False)
    honey_type = Column(String, nullable=False)
    
    yard_id = Column(String, nullable=True)
    hives_harvested = Column(Integer, nullable=True)
    harvest_img_url = Column(String, nullable=True)
    
    metadata_cid = Column(String, nullable=True)
    tx_hash = Column(String, nullable=True)
    status = Column(String, nullable=False)
    lab_verified = Column(Boolean, default=False)
    current_custodian = Column(String, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    beekeeper = relationship("Beekeeper", back_populates="batches")

class WhatsAppUser(Base):
    __tablename__ = "whatsapp_users"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    wa_id = Column(String, unique=True, nullable=False)
    beekeeper_id = Column(String, ForeignKey("beekeepers.id"), nullable=True)
    language = Column(String, default="en")
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    beekeeper = relationship("Beekeeper", back_populates="whatsapp_users")
    diagnostics = relationship("DiagnosticReport", back_populates="user")

class DiagnosticReport(Base):
    __tablename__ = "diagnostic_reports"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    wa_id = Column(String, ForeignKey("whatsapp_users.wa_id"))
    type = Column(String, nullable=False) # 'IMAGE' or 'AUDIO'
    media_url = Column(String, nullable=True)
    detection_result = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    severity = Column(String, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("WhatsAppUser", back_populates="diagnostics")

"""SQLAlchemy ORM models for actors and beekeepers."""
import enum
import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, Enum as SAEnum, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class ActorRole(str, enum.Enum):
    ADMIN = "admin"
    BEEKEEPER = "beekeeper"
    PROCESSOR = "processor"
    LAB = "lab"
    DISTRIBUTOR = "distributor"
    RETAILER = "retailer"


class Actor(Base):
    __tablename__ = "actors"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role = Column(SAEnum(ActorRole, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    name = Column(String, nullable=False)
    region = Column(String)
    wallet_address = Column(String)
    kyc_status = Column(String, default="pending")
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    beekeeper = relationship("Beekeeper", back_populates="actor", uselist=False)
    from_custody_events = relationship(
        "CustodyEvent",
        foreign_keys="CustodyEvent.from_actor_id",
        back_populates="from_actor",
    )
    to_custody_events = relationship(
        "CustodyEvent",
        foreign_keys="CustodyEvent.to_actor_id",
        back_populates="to_actor",
    )


class Beekeeper(Base):
    __tablename__ = "beekeepers"

    actor_id = Column(UUID(as_uuid=True), ForeignKey("actors.id"), primary_key=True)
    cooperative_id = Column(String)
    village = Column(String)
    district = Column(String)
    state = Column(String)

    actor = relationship("Actor", back_populates="beekeeper")
    hives = relationship("Hive", back_populates="beekeeper")

"""Models package — import all ORM classes so Alembic autogenerate sees them."""
from app.models.actor import Actor, ActorRole, Beekeeper  # noqa: F401
from app.models.hive import Hive, SensorReading  # noqa: F401
from app.models.batch import (  # noqa: F401
    AiInference,
    Batch,
    BatchStatus,
    Certificate,
    CustodyEvent,
    Harvest,
)
from app.models.qr import QrScan, QrToken  # noqa: F401

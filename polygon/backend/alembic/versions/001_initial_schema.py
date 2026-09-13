"""Initial schema — all HoneyChain tables.

Revision ID: 001
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # actors
    op.create_table(
        "actors",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("role", sa.Enum("admin", "beekeeper", "processor", "lab", "distributor", "retailer", name="actorrole"), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("region", sa.String()),
        sa.Column("wallet_address", sa.String()),
        sa.Column("kyc_status", sa.String(), server_default="pending"),
        sa.Column("hashed_password", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.PrimaryKeyConstraint("id"),
    )

    # beekeepers
    op.create_table(
        "beekeepers",
        sa.Column("actor_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("cooperative_id", sa.String()),
        sa.Column("village", sa.String()),
        sa.Column("district", sa.String()),
        sa.Column("state", sa.String()),
        sa.ForeignKeyConstraint(["actor_id"], ["actors.id"]),
        sa.PrimaryKeyConstraint("actor_id"),
    )

    # hives
    op.create_table(
        "hives",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("beekeeper_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("device_id", sa.String()),
        sa.Column("region_public", sa.String()),
        sa.Column("gps_encrypted", sa.String()),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["beekeeper_id"], ["beekeepers.actor_id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # sensor_readings
    op.create_table(
        "sensor_readings",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("hive_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("ts", sa.DateTime(), nullable=False, index=True),
        sa.Column("temperature_c", sa.Float()),
        sa.Column("humidity_pct", sa.Float()),
        sa.Column("pressure_hpa", sa.Float()),
        sa.Column("weight_kg", sa.Float()),
        sa.Column("battery_pct", sa.Float()),
        sa.Column("source", sa.String(), server_default="mqtt"),
        sa.Column("is_simulated", sa.Boolean(), server_default="false"),
        sa.ForeignKeyConstraint(["hive_id"], ["hives.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # harvests
    op.create_table(
        "harvests",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("hive_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("harvest_date", sa.DateTime(), nullable=False),
        sa.Column("quantity_g", sa.Integer(), nullable=False),
        sa.Column("floral_source", sa.String()),
        sa.Column("notes", sa.Text()),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["hive_id"], ["hives.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # batches
    op.create_table(
        "batches",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("batch_code", sa.String(), nullable=False, unique=True),
        sa.Column("batch_hash", sa.String(), nullable=False),
        sa.Column("harvest_id", postgresql.UUID(as_uuid=True)),
        sa.Column("status", sa.Enum(
            "Created", "Harvested", "Processed", "LabVerified", "Packaged",
            "InDistribution", "AtRetail", "Sold", "Recalled", "Rejected",
            name="batchstatus"
        ), server_default="Created"),
        sa.Column("metadata_cid", sa.String()),
        sa.Column("metadata_hash", sa.String()),
        sa.Column("contract_address", sa.String()),
        sa.Column("create_tx_hash", sa.String()),
        sa.Column("current_custodian_id", postgresql.UUID(as_uuid=True)),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["harvest_id"], ["harvests.id"]),
        sa.ForeignKeyConstraint(["current_custodian_id"], ["actors.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # certificates
    op.create_table(
        "certificates",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("batch_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("lab_actor_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("certificate_hash", sa.String(), nullable=False),
        sa.Column("cid", sa.String()),
        sa.Column("tx_hash", sa.String()),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["batch_id"], ["batches.id"]),
        sa.ForeignKeyConstraint(["lab_actor_id"], ["actors.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # custody_events
    op.create_table(
        "custody_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("batch_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("from_actor_id", postgresql.UUID(as_uuid=True)),
        sa.Column("to_actor_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("stage", sa.String(), nullable=False),
        sa.Column("tx_hash", sa.String()),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["batch_id"], ["batches.id"]),
        sa.ForeignKeyConstraint(["from_actor_id"], ["actors.id"]),
        sa.ForeignKeyConstraint(["to_actor_id"], ["actors.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # ai_inferences
    op.create_table(
        "ai_inferences",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("hive_id", postgresql.UUID(as_uuid=True)),
        sa.Column("batch_id", postgresql.UUID(as_uuid=True)),
        sa.Column("model_version", sa.String(), nullable=False),
        sa.Column("input_hash", sa.String(), nullable=False),
        sa.Column("prediction", sa.String(), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["hive_id"], ["hives.id"]),
        sa.ForeignKeyConstraint(["batch_id"], ["batches.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # qr_tokens
    op.create_table(
        "qr_tokens",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("batch_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("nonce_hash", sa.String(), nullable=False),
        sa.Column("signature", sa.String(), nullable=False),
        sa.Column("active", sa.Boolean(), server_default="true"),
        sa.Column("scan_count", sa.Integer(), server_default="0"),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["batch_id"], ["batches.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # qr_scans
    op.create_table(
        "qr_scans",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("qr_token_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("scanned_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("ip_region", sa.String()),
        sa.Column("user_agent", sa.String()),
        sa.Column("status", sa.String(), server_default="ok"),
        sa.ForeignKeyConstraint(["qr_token_id"], ["qr_tokens.id"]),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("qr_scans")
    op.drop_table("qr_tokens")
    op.drop_table("ai_inferences")
    op.drop_table("custody_events")
    op.drop_table("certificates")
    op.drop_table("batches")
    op.drop_table("harvests")
    op.drop_table("sensor_readings")
    op.drop_table("hives")
    op.drop_table("beekeepers")
    op.drop_table("actors")
    op.execute("DROP TYPE IF EXISTS actorrole")
    op.execute("DROP TYPE IF EXISTS batchstatus")

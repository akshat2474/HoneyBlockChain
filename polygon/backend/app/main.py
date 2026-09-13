"""HoneyChain FastAPI application entry point."""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, beekeepers, hives, batches, verify, ai
from app.services.mqtt_subscriber import start_mqtt_subscriber

app = FastAPI(
    title="HoneyChain API",
    description=(
        "Backend for the HoneyChain honey provenance system. "
        "Connects beekeepers, IoT sensors, AI inference, IPFS, "
        "and the Polygon Amoy blockchain."
    ),
    version="0.2.0",
)

# Allow Flutter web and local development origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Tighten to specific origins before production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ──────────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(beekeepers.router)
app.include_router(hives.router)
app.include_router(batches.router)
app.include_router(verify.router)
app.include_router(ai.router)


# ── Startup / Shutdown ────────────────────────────────────────────────────────
@app.on_event("startup")
def on_startup() -> None:
    start_mqtt_subscriber()


# ── Health / legacy endpoints ─────────────────────────────────────────────────
@app.get("/", tags=["health"])
def health_check():
    return {"status": "ok", "message": "HoneyChain API is running!", "version": "0.2.0"}


# ── Legacy endpoint (kept for backward compatibility with existing Flutter demo) ──
from fastapi import HTTPException
from pydantic import BaseModel
import json
from datetime import datetime
from app.services import blockchain, ipfs


class _LegacyBatchRequest(BaseModel):
    batchId: str
    quantityGrams: int
    honeyType: str
    region: str


@app.post("/create-batch", tags=["legacy"], include_in_schema=True)
def legacy_create_batch(req: _LegacyBatchRequest):
    """
    Legacy endpoint kept for backward compatibility.
    Prefer POST /batch (authenticated) for new integrations.
    """
    metadata = {
        "batchId": req.batchId,
        "honeyType": req.honeyType,
        "region": req.region,
        "quantityGrams": req.quantityGrams,
        "timestamp": datetime.utcnow().isoformat(),
    }
    metadata_str = json.dumps(metadata, sort_keys=True)

    try:
        cid, _meta_hash = ipfs.upload_json(metadata)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"IPFS upload failed: {exc}")

    try:
        tx_hash = blockchain.create_batch_tx(
            batch_code=req.batchId,
            quantity_grams=req.quantityGrams,
            harvest_timestamp=int(datetime.utcnow().timestamp()),
            metadata_cid=cid,
            metadata_json_str=metadata_str,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))

    return {
        "status": "success",
        "message": "Batch uploaded to IPFS and committed to Polygon!",
        "ipfs_cid": cid,
        "ipfs_url": f"https://gateway.pinata.cloud/ipfs/{cid}",
        "transaction_hash": tx_hash,
    }

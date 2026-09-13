"""AI inference router — stub endpoint for disease detection.

The AI team will replace the body of `_run_inference` with their
EfficientNet-B0 model. The rest of the endpoint (input validation,
hashing, DB persistence, response schema) is production-ready.
"""
from __future__ import annotations

import hashlib
from datetime import datetime

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth import get_current_actor
from app.database import get_db
from app.models.actor import Actor
from app.models.batch import AiInference

router = APIRouter(prefix="/disease-detection", tags=["ai"])

# Swap this version string when the AI team integrates their real model
_MODEL_VERSION = "bee-health-efficientnet-b0-stub-v0.1"

VALID_PREDICTIONS = {"healthy", "varroa_suspected", "pollen_carrier", "uncertain"}


class InferenceResponse(BaseModel):
    prediction: str
    confidence: float
    model_version: str
    inference_timestamp: str
    input_image_hash: str
    inference_id: str
    warning: str | None = None


def _hash_image(image_bytes: bytes) -> str:
    return hashlib.sha256(image_bytes).hexdigest()


def _run_inference(_image_bytes: bytes) -> tuple[str, float]:
    """
    === AI TEAM: replace this stub with real model inference ===

    Input:  raw image bytes (JPEG/PNG)
    Return: (prediction_label, confidence_score)
            prediction_label must be one of: healthy | varroa_suspected | pollen_carrier | uncertain
            confidence_score: float in [0.0, 1.0]
    """
    # Stub always returns uncertain until the real model is integrated
    return "uncertain", 0.50


@router.post("/", response_model=InferenceResponse)
async def disease_detection(
    image: UploadFile = File(..., description="Bee image JPEG/PNG"),
    hive_id: str | None = Form(None, description="Optional hive UUID to link inference"),
    db: Session = Depends(get_db),
    actor: Actor = Depends(get_current_actor),
):
    """
    Run bee disease detection on an uploaded image.

    Returns prediction class, confidence, model version, and a SHA-256
    hash of the input image (for audit trail and on-chain inclusion).
    """
    image_bytes = await image.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty image file")

    image_hash = _hash_image(image_bytes)
    prediction, confidence = _run_inference(image_bytes)

    warning = None
    if confidence < 0.70:
        prediction = "uncertain"
        warning = "Confidence below 0.70 — manual inspection required"

    inference = AiInference(
        hive_id=hive_id,
        model_version=_MODEL_VERSION,
        input_hash=image_hash,
        prediction=prediction,
        confidence=confidence,
    )
    db.add(inference)
    db.commit()
    db.refresh(inference)

    return InferenceResponse(
        prediction=prediction,
        confidence=confidence,
        model_version=_MODEL_VERSION,
        inference_timestamp=inference.created_at.isoformat(),
        input_image_hash=image_hash,
        inference_id=str(inference.id),
        warning=warning,
    )

"""Beekeepers router."""
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import get_current_actor, require_role
from app.database import get_db
from app.models.actor import Actor, ActorRole, Beekeeper
from app.schemas.actor import ActorResponse

router = APIRouter(prefix="/beekeeper", tags=["beekeepers"])


@router.get("/{beekeeper_id}", response_model=ActorResponse)
def get_beekeeper(
    beekeeper_id: uuid.UUID,
    db: Session = Depends(get_db),
    _actor: Actor = Depends(get_current_actor),
):
    """Fetch a beekeeper's profile by actor ID."""
    bk = db.query(Beekeeper).filter(Beekeeper.actor_id == beekeeper_id).first()
    if not bk:
        raise HTTPException(status_code=404, detail="Beekeeper not found")
    return bk.actor


@router.get("/", response_model=list[ActorResponse])
def list_beekeepers(
    db: Session = Depends(get_db),
    _actor: Actor = Depends(require_role(ActorRole.ADMIN)),
):
    """Admin-only: list all registered beekeepers."""
    beekeepers = db.query(Beekeeper).all()
    return [bk.actor for bk in beekeepers]

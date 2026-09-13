"""Auth router — register actors and issue JWT tokens."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import create_access_token, hash_password, verify_password
from app.database import get_db
from app.models.actor import Actor, ActorRole, Beekeeper
from app.schemas.actor import ActorRegisterRequest, ActorResponse, LoginRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])


def _create_beekeeper_profile(db: Session, actor: Actor, req: ActorRegisterRequest) -> None:
    beekeeper = Beekeeper(
        actor_id=actor.id,
        cooperative_id=req.cooperative_id,
        village=req.village,
        district=req.district,
        state=req.state,
    )
    db.add(beekeeper)


@router.post("/register", response_model=ActorResponse, status_code=status.HTTP_201_CREATED)
def register(req: ActorRegisterRequest, db: Session = Depends(get_db)):
    """
    Register a new actor. Open endpoint — in production, admin approval should
    gate non-beekeeper roles before their blockchain wallet is granted a contract role.
    """
    existing = db.query(Actor).filter(Actor.name == req.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Name already registered")

    actor = Actor(
        role=req.role,
        name=req.name,
        region=req.region,
        wallet_address=req.wallet_address,
        hashed_password=hash_password(req.password),
    )
    db.add(actor)
    db.flush()  # get actor.id before committing

    if req.role == ActorRole.BEEKEEPER:
        _create_beekeeper_profile(db, actor, req)

    db.commit()
    db.refresh(actor)
    return actor


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    actor = db.query(Actor).filter(Actor.name == req.name).first()
    if not actor or not verify_password(req.password, actor.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(actor.id, actor.role)
    return TokenResponse(access_token=token, actor_id=actor.id, role=actor.role)

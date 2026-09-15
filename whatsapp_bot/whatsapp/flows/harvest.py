import time
import hashlib
from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.i18n import t  # Bug fix #7: module now exists
from database import SessionLocal
from models import HoneyBatch, Beekeeper


async def handle_harvest(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    """
    Full harvest registration flow (4 steps: yard -> hives -> weight -> varietal).

    States:
        HARVEST_YARD_ID  -> user gives yard/apiary name  -> HARVEST_HIVES
        HARVEST_HIVES    -> user gives hive count         -> HARVEST_VOLUME
        HARVEST_VOLUME   -> user gives weight in kg       -> HARVEST_VARIETAL
        HARVEST_VARIETAL -> user gives honey type         -> IDLE (save to DB)
        HARVEST_IMAGE    -> optional image, skip for now  -> IDLE
    """
    # Bug fix #6: this flow was previously dead code; handler.py now routes to it.
    # Bug fix #24: field names corrected to match the actual HoneyBatch model.
    text = data.get("english_text", "").strip()

    if text.lower() == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(wa_id, t(lang, "general.cancelled"), lang)
        return

    # ── Step 1: yard / apiary name ────────────────────────────────────────────
    if state == ConversationState.HARVEST_YARD_ID:
        if len(text) < 2:
            await whatsapp_client.send_text(
                wa_id, "Too short. Please enter a valid yard / apiary name:", lang
            )
            return

        data["yard_id"] = text
        await whatsapp_client.send_text(wa_id, t(lang, "harvest.step2"), lang)
        await redis_service.set_session(wa_id, ConversationState.HARVEST_HIVES, data)
        return

    # ── Step 2: number of hives harvested ────────────────────────────────────
    if state == ConversationState.HARVEST_HIVES:
        digits = "".join(filter(str.isdigit, text))
        if not digits:
            await whatsapp_client.send_text(wa_id, t(lang, "general.invalid_number"), lang)
            return

        data["hives_harvested"] = int(digits)
        await whatsapp_client.send_text(wa_id, t(lang, "harvest.step3"), lang)
        await redis_service.set_session(wa_id, ConversationState.HARVEST_VOLUME, data)
        return

    # ── Step 3: total weight in kg ────────────────────────────────────────────
    if state == ConversationState.HARVEST_VOLUME:
        digits = "".join(filter(lambda c: c.isdigit() or c == ".", text))
        if not digits:
            await whatsapp_client.send_text(wa_id, t(lang, "general.invalid_number"), lang)
            return
        try:
            weight_kg = float(digits)
        except ValueError:
            await whatsapp_client.send_text(wa_id, t(lang, "general.invalid_number"), lang)
            return

        data["weight_kg"] = weight_kg
        await whatsapp_client.send_text(wa_id, t(lang, "harvest.step4"), lang)
        await redis_service.set_session(wa_id, ConversationState.HARVEST_VARIETAL, data)
        return

    # ── Step 4: honey type / floral source -> save to DB ─────────────────────
    if state == ConversationState.HARVEST_VARIETAL:
        if len(text) < 2:
            await whatsapp_client.send_text(
                wa_id,
                "Please enter a valid honey type (e.g., Mustard, Litchi, Multiflora):",
                lang,
            )
            return

        data["varietal"] = text

        # Generate a deterministic, human-readable batch ID
        raw       = f"{wa_id}-{int(time.time())}"
        short_hash = hashlib.sha256(raw.encode()).hexdigest()[:10].upper()
        batch_id_display = f"BATCH-{short_hash}"

        db = SessionLocal()
        try:
            # Look up beekeeper DB primary key (bug fix #24: beekeeper_id is a FK to id, not phone)
            bk = db.query(Beekeeper).filter(Beekeeper.phone == wa_id).first()

            batch = HoneyBatch(
                batch_id_hash=batch_id_display,           # correct field name
                beekeeper_id=bk.id if bk else None,       # correct FK field
                quantity_grams=int(data["weight_kg"] * 1000),  # model stores grams
                honey_type=data["varietal"],               # correct field name
                yard_id=data.get("yard_id", ""),
                hives_harvested=data.get("hives_harvested", 0),
                status="PENDING",
                current_custodian=wa_id,
            )
            db.add(batch)
            db.commit()
        except Exception as e:
            print(f"DB Harvest Error: {e}")
            db.rollback()
            await whatsapp_client.send_text(
                wa_id, "Failed to save harvest. Please try again.", lang
            )
            await redis_service.set_session(wa_id, ConversationState.IDLE, {})
            return
        finally:
            db.close()

        reply = t(lang, "harvest.success").format(
            batch_id=batch_id_display,
            qty=data["weight_kg"],
            type=data["varietal"],
        )
        await whatsapp_client.send_text(wa_id, reply, lang)
        await redis_service.set_session(wa_id, ConversationState.IDLE, {})
        return

    # ── HARVEST_IMAGE (optional — skipped for now) ────────────────────────────
    if state == ConversationState.HARVEST_IMAGE:
        await whatsapp_client.send_text(wa_id, "Harvest recording complete!", lang)
        await redis_service.set_session(wa_id, ConversationState.IDLE, {})
        return

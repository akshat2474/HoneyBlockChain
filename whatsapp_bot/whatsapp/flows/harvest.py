import time
from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from database import SessionLocal
from models import HoneyBatch
from whatsapp.i18n import t

async def handle_harvest(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    msg_type = message.get("type")
    text = message.get("text", {}).get("body", "").strip() if msg_type == "text" else ""

    if text.lower() == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(wa_id, t(lang, "general.cancelled"))
        return

    if state == ConversationState.HARVEST_YARD_ID:
        await whatsapp_client.send_text(wa_id, t(lang, "harvest.step1"))
        await redis_service.set_session(wa_id, ConversationState.HARVEST_WEIGHT, data)
        return

    if state == ConversationState.HARVEST_WEIGHT:
        if len(text) < 2:
            await whatsapp_client.send_text(wa_id, "⚠️ Too short. Please enter a valid yard name:")
            return
            
        data["yard_id"] = text
        await whatsapp_client.send_text(wa_id, t(lang, "harvest.step2"))
        await redis_service.set_session(wa_id, ConversationState.HARVEST_VARIETAL, data)
        return

    if state == ConversationState.HARVEST_VARIETAL:
        if not text.isdigit():
            await whatsapp_client.send_text(wa_id, t(lang, "general.invalid_number"))
            return
            
        data["weight"] = float(text)
        await whatsapp_client.send_text(wa_id, t(lang, "harvest.step3"))
        await redis_service.set_session(wa_id, ConversationState.HARVEST_IMAGE, data)
        return

    if state == ConversationState.HARVEST_IMAGE:
        # Note: In the real app, we might ask for an image, but skipping directly to success for now as per schema
        data["varietal"] = text
        batch_id = f"BATCH-{int(time.time())}"
        
        # Save to DB
        db = SessionLocal()
        try:
            batch = HoneyBatch(
                batch_id=batch_id,
                producer_id=wa_id,
                yard_id=data["yard_id"],
                weight_kg=data["weight"],
                floral_source=data["varietal"],
                current_custodian=wa_id
            )
            db.add(batch)
            db.commit()
        except Exception as e:
            print("DB Harvest Error:", e)
            db.rollback()
        finally:
            db.close()

        reply = t(lang, "harvest.success").format(
            batch_id=batch_id,
            qty=data["weight"],
            type=data["varietal"]
        )
        await whatsapp_client.send_text(wa_id, reply)
        await redis_service.set_session(wa_id, ConversationState.IDLE, data)
        return

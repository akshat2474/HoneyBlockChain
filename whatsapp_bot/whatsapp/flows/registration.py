from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from database import SessionLocal
from models import Beekeeper
from whatsapp.i18n import t

async def handle_registration(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    msg_type = message.get("type")
    text = message.get("text", {}).get("body", "").strip() if msg_type == "text" else ""

    if text.lower() == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(wa_id, t(lang, "general.cancelled"))
        return

    if state == ConversationState.REGISTRATION_NAME:
        if len(text) < 3:
            await whatsapp_client.send_text(wa_id, t(lang, "reg.err_name"))
            return
        
        data["name"] = text
        data["phone"] = wa_id
        
        await whatsapp_client.send_text(wa_id, t(lang, "reg.step2").format(name=text, phone=wa_id))
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_REGION, data)
        return

    if state == ConversationState.REGISTRATION_REGION:
        data["region"] = text
        await whatsapp_client.send_text(wa_id, t(lang, "reg.step3"))
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_CAPACITY, data)
        return

    if state == ConversationState.REGISTRATION_CAPACITY:
        if not text.isdigit():
            await whatsapp_client.send_text(wa_id, t(lang, "general.invalid_number"))
            return
        data["hives"] = int(text)
        await whatsapp_client.send_text(wa_id, t(lang, "reg.step4"))
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_PRACTICES, data)
        return

    if state == ConversationState.REGISTRATION_PRACTICES:
        data["practices"] = text
        
        # Save to DB
        db = SessionLocal()
        try:
            bk = Beekeeper(
                name=data["name"],
                phone=data["phone"],
                region=data["region"],
                hives_count=data["hives"],
                practices=data["practices"]
            )
            db.add(bk)
            db.commit()
        except Exception as e:
            print("DB Error:", e)
            db.rollback()
        finally:
            db.close()

        # Reply
        reply = t(lang, "reg.success").format(
            name=data["name"],
            phone=data["phone"],
            region=data["region"],
            hives=data["hives"],
            practices=data["practices"]
        )
        await whatsapp_client.send_text(wa_id, reply)
        await redis_service.set_session(wa_id, ConversationState.IDLE, data)
        return

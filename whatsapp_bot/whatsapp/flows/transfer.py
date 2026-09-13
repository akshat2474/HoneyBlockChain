from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from database import SessionLocal
from models import HoneyBatch
from whatsapp.i18n import t

async def handle_transfer(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    msg_type = message.get("type")
    text = message.get("text", {}).get("body", "").strip() if msg_type == "text" else ""

    if text.lower() == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(wa_id, t(lang, "general.cancelled"))
        return

    if state == ConversationState.TRANSFER_BATCH_ID:
        await whatsapp_client.send_text(wa_id, t(lang, "transfer.step1"))
        await redis_service.set_session(wa_id, ConversationState.TRANSFER_BUYER_ID, data)
        return

    if state == ConversationState.TRANSFER_BUYER_ID:
        if not text.startswith("BATCH-"):
            await whatsapp_client.send_text(wa_id, "⚠️ Invalid format. Batch ID must start with 'BATCH-'.")
            return
            
        data["batch_id"] = text
        await whatsapp_client.send_text(wa_id, t(lang, "transfer.step2"))
        await redis_service.set_session(wa_id, ConversationState.TRANSFER_CONFIRM, data)
        return

    if state == ConversationState.TRANSFER_CONFIRM:
        data["buyer_id"] = text
        
        # Save to DB
        db = SessionLocal()
        success = False
        try:
            batch = db.query(HoneyBatch).filter(HoneyBatch.batch_id == data["batch_id"]).first()
            if batch:
                if batch.current_custodian == wa_id:
                    batch.current_custodian = data["buyer_id"]
                    db.commit()
                    success = True
                else:
                    await whatsapp_client.send_text(wa_id, "⚠️ You do not own this batch.")
            else:
                await whatsapp_client.send_text(wa_id, "⚠️ Batch not found.")
        except Exception as e:
            print("DB Transfer Error:", e)
            db.rollback()
        finally:
            db.close()

        if success:
            reply = t(lang, "transfer.success").format(
                batch_id=data["batch_id"],
                buyer=data["buyer_id"]
            )
            await whatsapp_client.send_text(wa_id, reply)
            await redis_service.set_session(wa_id, ConversationState.IDLE, data)
        else:
            await redis_service.set_session(wa_id, ConversationState.IDLE, data)
        return

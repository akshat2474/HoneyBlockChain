from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.i18n import t  # Bug fix #7: module now exists
from whatsapp.flows.main_menu import handle_main_menu
from database import SessionLocal
from models import HoneyBatch


async def handle_transfer(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    """
    FSM handler for the custody-transfer flow.

    Entry point: caller sets state=TRANSFER_BATCH_ID and sends the step1 prompt
                 BEFORE calling this function for the first time.

    States:
        TRANSFER_BATCH_ID  -> user provides batch ID  -> TRANSFER_BUYER_ID
        TRANSFER_BUYER_ID  -> user provides buyer num  -> TRANSFER_CONFIRM
        TRANSFER_CONFIRM   -> user confirms YES/NO     -> MAIN_MENU
    """
    text = data.get("english_text", "").strip()

    if text.lower() in ("cancel", "no", "n"):
        await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})
        await whatsapp_client.send_text(wa_id, "❌ Transfer cancelled.", lang)
        await handle_main_menu(wa_id, lang)
        return

    # ── Step 1: user provides the batch ID they want to transfer ──────────────
    if state == ConversationState.TRANSFER_BATCH_ID:
        if not text.upper().startswith("BATCH-"):
            await whatsapp_client.send_text(
                wa_id,
                "❌ Invalid format. Batch ID must start with 'BATCH-' (e.g., BATCH-A1B2C3D4).\n\n"
                + t(lang, "transfer.step1"),
                lang,
            )
            return

        data["batch_id"] = text.upper()
        await whatsapp_client.send_text(wa_id, t(lang, "transfer.step2"), lang)
        await redis_service.set_session(wa_id, ConversationState.TRANSFER_BUYER_ID, data)
        return

    # ── Step 2: user provides the buyer's phone number ────────────────────────
    if state == ConversationState.TRANSFER_BUYER_ID:
        digits = "".join(filter(str.isdigit, text))
        if len(digits) < 10:
            await whatsapp_client.send_text(
                wa_id,
                "❌ Invalid phone number. Please enter digits only "
                "(e.g., 919876543210 for an Indian number):",
                lang,
            )
            return

        data["buyer_id"] = digits
        confirm_text = (
            f"Please confirm the transfer:\n\n"
            f"Batch ID: {data['batch_id']}\n"
            f"Transfer to: +{digits}\n\n"
            f"Reply YES to confirm or CANCEL to abort."
        )
        await whatsapp_client.send_text(wa_id, confirm_text, lang)
        await redis_service.set_session(wa_id, ConversationState.TRANSFER_CONFIRM, data)
        return

    # ── Step 3: confirmation & execute transfer ───────────────────────────────
    if state == ConversationState.TRANSFER_CONFIRM:
        yes_words = ("yes", "y", "confirm", "ok", "haan", "ha")
        if text.lower() not in yes_words:
            await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})
            await whatsapp_client.send_text(wa_id, "❌ Transfer cancelled.", lang)
            await handle_main_menu(wa_id, lang)
            return

        db = SessionLocal()
        success = False
        reply = ""
        try:
            batch = (
                db.query(HoneyBatch)
                .filter(HoneyBatch.batch_id_hash == data["batch_id"])
                .first()
            )
            if not batch:
                reply = f"❌ Batch '{data['batch_id']}' not found. Please verify the Batch ID."
            elif batch.current_custodian != wa_id:
                reply = "❌ You do not own this batch and cannot transfer it."
            else:
                batch.current_custodian = data["buyer_id"]
                db.commit()
                success = True
                reply = t(lang, "transfer.success").format(
                    batch_id=data["batch_id"],
                    buyer=data["buyer_id"],
                )
        except Exception as e:
            print(f"DB Transfer Error: {e}")
            db.rollback()
            reply = "❌ Transfer failed due to a server error. Please try again."
        finally:
            db.close()

        buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
        await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
        await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})
        return


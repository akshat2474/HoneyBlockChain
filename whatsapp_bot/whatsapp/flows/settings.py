from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from database import SessionLocal
from models import WhatsAppUser

async def handle_settings(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    msg_type = message.get("type")
    interactive_id = (
        message.get("interactive", {}).get("button_reply", {}).get("id", "")
        or message.get("interactive", {}).get("list_reply", {}).get("id", "")
    )
    text = message.get("text", {}).get("body", "").strip() if msg_type == "text" else ""

    if text.lower() == "cancel":
        await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})
        await whatsapp_client.send_text(wa_id, "❌ Settings cancelled. Returning to main menu.", lang)
        return

    if state == ConversationState.SETTINGS_CHOOSE_LANGUAGE:
        # We expect an interactive button reply or a language code
        selected_lang = "en"
        if interactive_id:
            # Assuming IDs like 'lang_hi', 'lang_bn'
            if interactive_id.startswith("lang_"):
                selected_lang = interactive_id.replace("lang_", "")
        elif text:
            # Basic mapping for text input
            mapping = {"english": "en", "hindi": "hi", "hinglish": "hi", "bengali": "bn", "bangla": "bn", "telugu": "te"}
            text_lower = text.lower()
            if text_lower in mapping:
                selected_lang = mapping[text_lower]
            else:
                await whatsapp_client.send_text(wa_id, "❌ Invalid language. Please choose from English, Hindi, or Bengali.", lang)
                return

        # Update User in DB
        db = SessionLocal()
        try:
            user = db.query(WhatsAppUser).filter(WhatsAppUser.wa_id == wa_id).first()
            if user:
                user.language = selected_lang
                db.commit()
        except Exception as e:
            print(f"DB Settings Error: {e}")
            db.rollback()
        finally:
            db.close()

        # Confirmation
        lang_names = {"en": "English", "hi": "Hindi", "bn": "Bengali"}
        lang_name = lang_names.get(selected_lang, "English")

        reply = f"✅ Language updated to {lang_name}!\n\nAll future messages will be in this language. Send 'menu' to return."
        await whatsapp_client.send_text(wa_id, reply, selected_lang)
        await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": selected_lang})
        return

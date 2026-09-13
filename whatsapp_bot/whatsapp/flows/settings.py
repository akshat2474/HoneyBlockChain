from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.i18n import t
from database import SessionLocal
from models import WhatsAppUser
from .main_menu import handle_main_menu

async def handle_settings(wa_id: str, message: dict, state: str, data: dict):
    if state == ConversationState.SETTINGS_CHOOSE_LANGUAGE:
        msg_type = message.get("type")
        interactive_id = ""
        if msg_type == "interactive":
            interactive = message.get("interactive", {})
            if interactive.get("type") == "list_reply":
                interactive_id = interactive.get("list_reply", {}).get("id", "")
            elif interactive.get("type") == "button_reply":
                interactive_id = interactive.get("button_reply", {}).get("id", "")
        
        # Determine choice
        chosen_lang = None
        if interactive_id == "lang_en":
            chosen_lang = "en"
        elif interactive_id == "lang_hi":
            chosen_lang = "hi"
            
        if chosen_lang:
            # Update Database
            db = SessionLocal()
            try:
                user = db.query(WhatsAppUser).filter(WhatsAppUser.wa_id == wa_id).first()
                if not user:
                    user = WhatsAppUser(wa_id=wa_id, language=chosen_lang)
                    db.add(user)
                else:
                    user.language = chosen_lang
                db.commit()
            except Exception as e:
                print("DB Error setting language:", e)
                db.rollback()
            finally:
                db.close()
                
            # Update cache
            data["language"] = chosen_lang
            await redis_service.set_session(wa_id, ConversationState.IDLE, data)
            
            # Send confirmation
            await whatsapp_client.send_text(wa_id, t(chosen_lang, "settings.lang_updated"))
            
            # Send main menu in new language
            await handle_main_menu(wa_id, chosen_lang)
        else:
            # Send prompt
            # Use interactive buttons for quick language selection
            await whatsapp_client.send_buttons(wa_id, t("en", "settings.choose_lang"), [
                {"type": "reply", "reply": {"id": "lang_en", "title": "English"}},
                {"type": "reply", "reply": {"id": "lang_hi", "title": "हिन्दी"}}
            ])
            await redis_service.set_session(wa_id, ConversationState.SETTINGS_CHOOSE_LANGUAGE, data)

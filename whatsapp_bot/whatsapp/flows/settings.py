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

    # If we reached here, the LLM global intercept in handler.py failed to detect the language name
    await whatsapp_client.send_text(
        wa_id, 
        "❌ I couldn't recognize that language. Please try typing the name of the language clearly (e.g., 'Telugu', 'Marathi'), or type 'cancel' to return to the menu.", 
        lang
    )
    return

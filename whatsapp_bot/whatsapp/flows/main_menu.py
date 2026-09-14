from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState

async def handle_main_menu(wa_id: str, lang: str = "en"):
    buttons = [
        {"type": "reply", "reply": {"id": "menu_hive_status", "title": "📡 Hive Status"}},
        {"type": "reply", "reply": {"id": "menu_ask_doubt", "title": "❓ Ask a Doubt"}}
    ]

    text = "👋 Welcome to HoneyBlockChain!\n\nPlease select an option below:"
    await whatsapp_client.send_buttons(wa_id, text, buttons, lang)
    await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})

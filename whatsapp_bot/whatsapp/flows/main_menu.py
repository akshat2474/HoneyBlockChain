from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState

async def handle_main_menu(wa_id: str, lang: str = "en"):
    sections = [
        {
            "title": "HoneyBlockChain Menu",
            "rows": [
                {"id": "menu_hive_status", "title": "📡 IoT Hive Status", "description": "Check temperature & humidity"},
                {"id": "menu_ask_doubt", "title": "❓ Ask a Doubt", "description": "Ask the AI Assistant a question"}
            ]
        }
    ]

    text = "👋 Welcome to HoneyBlockChain!\n\nPlease tap the menu below to select an option:"
    await whatsapp_client.send_list(wa_id, text, sections, lang)
    await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})

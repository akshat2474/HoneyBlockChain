from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState

async def handle_main_menu(wa_id: str, lang: str = "en"):
    # We use a List message instead of buttons to accommodate more than 3 options
    sections = [
        {
            "title": "Main Menu",
            "rows": [
                {"id": "menu_box_condition", "title": "Honey Box Condition", "description": "Check IoT status of your hives"},
                {"id": "menu_health_care", "title": "Bees Health & Care", "description": "Diseases, Queen & Hive condition"},
                {"id": "menu_market_schemes", "title": "Harvest & Market", "description": "Subsidies, Prices & Registration"},
                {"id": "menu_transfer", "title": "Transfer Custody", "description": "Transfer a batch to a buyer"},
                {"id": "menu_batch_status", "title": "Verify Batch Status", "description": "Check batch details on blockchain"},
            ]
        }
    ]

    text = "👋 Welcome to HoneyBlockChain!\n\nPlease select an option from the menu below. You can also send me a text or voice message if you have a specific question!"
    await whatsapp_client.send_list(wa_id, text, sections, lang)
    await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})

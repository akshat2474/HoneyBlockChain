from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState

async def handle_main_menu(wa_id: str):
    sections = [
        {
            "title": "HoneyBlockChain Menu",
            "rows": [
                {"id": "menu_diagnostics", "title": "🤖 AI Diagnostics", "description": "Check Hive Health (Image/Audio)"},
                {"id": "menu_register", "title": "📋 Register Profile", "description": "Join as a Beekeeper"},
                {"id": "menu_harvest", "title": "🍯 Log Harvest", "description": "Generate Harvest Voucher"},
                {"id": "menu_transfer", "title": "🚚 Transfer Custody", "description": "Sell or transfer batch"},
                {"id": "menu_verify", "title": "🔍 Verify Batch", "description": "Trace batch on blockchain"},
            ]
        }
    ]

    await whatsapp_client.send_list(
        wa_id,
        "👋 *Welcome to HoneyBlockChain!*\n\nI am your AI Beekeeper Assistant. Please tap the menu below to select an option:",
        sections
    )
    await redis_service.set_session(wa_id, ConversationState.MAIN_MENU)

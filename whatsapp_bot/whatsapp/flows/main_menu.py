from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.i18n import t

async def handle_main_menu(wa_id: str, lang: str = "en"):
    sections = [
        {
            "title": t(lang, "menu.button_text"),
            "rows": [
                {"id": "menu_diagnostics", "title": t(lang, "menu.opt_diag"), "description": t(lang, "menu.desc_diag")},
                {"id": "menu_register", "title": t(lang, "menu.opt_reg"), "description": t(lang, "menu.desc_reg")},
                {"id": "menu_harvest", "title": t(lang, "menu.opt_harv"), "description": t(lang, "menu.desc_harv")},
                {"id": "menu_transfer", "title": t(lang, "menu.opt_trans"), "description": t(lang, "menu.desc_trans")},
                {"id": "menu_settings", "title": t(lang, "menu.opt_lang"), "description": t(lang, "menu.desc_lang")},
            ]
        }
    ]

    await whatsapp_client.send_list(
        wa_id,
        t(lang, "menu.welcome"),
        sections
    )
    await redis_service.set_session(wa_id, ConversationState.MAIN_MENU)

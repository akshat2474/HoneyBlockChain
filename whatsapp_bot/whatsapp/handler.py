from whatsapp.fsm import redis_service
from whatsapp.client import whatsapp_client
from whatsapp.states import ConversationState
from whatsapp.flows.main_menu import handle_main_menu
from whatsapp.flows.diagnostics import handle_diagnostics
from whatsapp.flows.registration import handle_registration
from whatsapp.flows.settings import handle_settings
from whatsapp.i18n import t
from database import SessionLocal
from models import WhatsAppUser

async def handle_message(message: dict):
    wa_id = message.get("from")
    msg_id = message.get("id")

    if not wa_id or not msg_id:
        return

    # 1. Deduplication
    is_duplicate = await redis_service.is_duplicate_message(msg_id)
    if is_duplicate:
        print(f"♻️ Ignored duplicate webhook message: {msg_id}")
        return

    # 2. Spam Cooldown
    is_spam = await redis_service.is_spamming(wa_id)
    if is_spam:
        print(f"⚠️ Ignored message due to spam cooldown: {wa_id}")
        return

    session = await redis_service.get_session(wa_id)
    state = session.get("state")
    data = session.get("data", {})

    # 3. DB Lookup / Language Initialization
    lang = data.get("language")
    if not lang:
        db = SessionLocal()
        try:
            user = db.query(WhatsAppUser).filter(WhatsAppUser.wa_id == wa_id).first()
            if user and user.language:
                lang = user.language
                data["language"] = lang
        finally:
            db.close()
    
    await whatsapp_client.mark_as_read(msg_id)

    # Extract text/interactive
    msg_type = message.get("type")
    text = ""
    interactive_id = ""

    if msg_type == "text":
        text = message.get("text", {}).get("body", "").lower().strip()
    elif msg_type == "interactive":
        interactive = message.get("interactive", {})
        if interactive.get("type") == "list_reply":
            interactive_id = interactive.get("list_reply", {}).get("id", "")
        elif interactive.get("type") == "button_reply":
            interactive_id = interactive.get("button_reply", {}).get("id", "")

    # Always go to menu if standard keywords are typed
    if text in ["hi", "hello", "menu", "start", "0", "नमस्ते", "main menu"]:
        if not lang:
            # First time ever interacting -> Go to language settings
            await handle_settings(wa_id, message, ConversationState.SETTINGS_CHOOSE_LANGUAGE, data)
        else:
            await handle_main_menu(wa_id, lang)
        return

    # Handle language setup flow exclusively if language isn't set
    if not lang or state == ConversationState.SETTINGS_CHOOSE_LANGUAGE:
        await handle_settings(wa_id, message, ConversationState.SETTINGS_CHOOSE_LANGUAGE, data)
        return

    # Handle menu selections
    if state in [ConversationState.MAIN_MENU, ConversationState.IDLE]:
        if interactive_id == "menu_diagnostics" or text == "1":
            await handle_diagnostics(wa_id, message, ConversationState.DIAGNOSTICS_SELECT, data)
            return
        elif interactive_id == "menu_register" or text == "2":
            await handle_registration(wa_id, message, ConversationState.REGISTRATION_NAME, data)
            return
        elif interactive_id == "menu_harvest" or text == "3":
            await whatsapp_client.send_text(wa_id, t(lang, "general.coming_soon"))
            return
        elif interactive_id == "menu_transfer" or text == "4":
            await whatsapp_client.send_text(wa_id, t(lang, "general.coming_soon"))
            return
        elif interactive_id == "menu_verify" or text == "5":
            await whatsapp_client.send_text(wa_id, t(lang, "general.coming_soon"))
            return
        elif interactive_id == "menu_settings":
            await handle_settings(wa_id, message, ConversationState.SETTINGS_CHOOSE_LANGUAGE, data)
            return
        else:
            # LLM Router Fallback for free-text
            from whatsapp.llm_router import classify_intent
            if text:
                intent_res = classify_intent(text)
                intent = intent_res.intent
                print(f"🧠 LLM Classified Intent: {intent} (Lang: {intent_res.detected_language})")
                
                if intent == "DIAGNOSTICS":
                    await handle_diagnostics(wa_id, message, ConversationState.DIAGNOSTICS_SELECT, data)
                    return
                elif intent == "REGISTRATION":
                    await handle_registration(wa_id, message, ConversationState.REGISTRATION_NAME, data)
                    return
                elif intent == "CHANGE_LANGUAGE":
                    await handle_settings(wa_id, message, ConversationState.SETTINGS_CHOOSE_LANGUAGE, data)
                    return
                elif intent == "HARVEST" or intent == "TRANSFER" or intent == "VERIFY":
                    await whatsapp_client.send_text(wa_id, t(lang, "general.coming_soon"))
                    return
                    
            # Default fallback
            await handle_main_menu(wa_id, lang)
            return

    # Route to active flow
    if state.startswith("DIAGNOSTICS_"):
        await handle_diagnostics(wa_id, message, state, data)
    elif state.startswith("REGISTRATION_"):
        await handle_registration(wa_id, message, state, data)
    elif state.startswith("SETTINGS_"):
        await handle_settings(wa_id, message, state, data)
    else:
        await handle_main_menu(wa_id, lang)

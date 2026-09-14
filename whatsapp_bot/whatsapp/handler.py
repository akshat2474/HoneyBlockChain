from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.flows.main_menu import handle_main_menu
from whatsapp.flows.registration import handle_registration
from database import SessionLocal
from models import WhatsAppUser
from whatsapp.llm_service import analyze_incoming_text, analyze_incoming_audio

def get_or_create_user(wa_id: str, default_lang: str = "en") -> WhatsAppUser:
    db = SessionLocal()
    try:
        user = db.query(WhatsAppUser).filter(WhatsAppUser.wa_id == wa_id).first()
        if not user:
            user = WhatsAppUser(wa_id=wa_id, language=default_lang)
            db.add(user)
            db.commit()
            db.refresh(user)
        return user
    finally:
        db.close()

def update_user_language(wa_id: str, new_lang: str):
    db = SessionLocal()
    try:
        user = db.query(WhatsAppUser).filter(WhatsAppUser.wa_id == wa_id).first()
        if user and user.language != new_lang:
            user.language = new_lang
            db.commit()
    finally:
        db.close()

async def handle_message(wa_id: str, message: dict):
    msg_type = message.get("type")
    msg_id = message.get("id")
    original_text = message.get("text", {}).get("body", "").strip() if msg_type == "text" else ""
    interactive_id = message.get("interactive", {}).get("button_reply", {}).get("id", "")
    
    # Mark message as read (blue ticks)
    if msg_id:
        await whatsapp_client.mark_as_read(msg_id)
    
    # 1. Translate incoming text/audio using LLM
    lang = "en"
    english_text = original_text
    intent = "UNKNOWN"
    
    if msg_type == "text" and original_text:
        analysis = analyze_incoming_text(original_text)
        lang = analysis.detected_language
        english_text = analysis.translated_english_text
        intent = analysis.intent
        print(f"🎤 [LLM TEXT IN] Lang: {lang} | Translated: {english_text} | Intent: {intent}")
    elif msg_type == "audio":
        media_id = message.get("audio", {}).get("id")
        if media_id:
            audio_bytes = await whatsapp_client.download_media(media_id)
            analysis = analyze_incoming_audio(audio_bytes)
            lang = analysis.detected_language
            english_text = analysis.translated_english_text
            intent = analysis.intent
            print(f"🎤 [LLM AUDIO IN] Lang: {lang} | Translated: {english_text} | Intent: {intent}")

    # 2. State Management
    state_data = await redis_service.get_session(wa_id)
    state = state_data.get("state", ConversationState.IDLE)
    data = state_data.get("data", {})
    
    # Save the english text into data so the flows don't have to re-translate
    data["english_text"] = english_text

    # 3. Check Database for Registration Status
    from models import Beekeeper
    db = SessionLocal()
    try:
        is_registered = db.query(Beekeeper).filter(Beekeeper.phone == wa_id).first() is not None
    finally:
        db.close()

    user_meta = get_or_create_user(wa_id, lang)
    if lang != "en" and lang != "UNKNOWN" and (msg_type == "text" or msg_type == "audio"):
        update_user_language(wa_id, lang)
    
    current_lang = user_meta.language

    # 4. Handle Global Intercepts (e.g. First-time registration or forced main menu)
    if state in [ConversationState.IDLE, ConversationState.MAIN_MENU]:
        if not is_registered:
            # Force registration
            if intent == "MAIN_MENU" or english_text.lower() in ["hi", "hello", "menu", "register"]:
                await handle_registration(wa_id, message, ConversationState.REGISTRATION_NAME, data, current_lang)
                return
        else:
            if intent == "MAIN_MENU" or english_text.lower() in ["hi", "hello", "menu"]:
                await handle_main_menu(wa_id, current_lang)
                return
                
            if interactive_id == "menu_hive_status" or intent == "HIVE_STATUS" or "status" in english_text.lower():
                # Mock IoT response
                iot_reply = "🍯 *IoT Hive Status*\n\n✅ Hive 1: Healthy (35°C, 45% Humidity)\n✅ Hive 2: Healthy (34°C, 46% Humidity)\n\nEverything looks good!"
                await whatsapp_client.send_text(wa_id, iot_reply, current_lang)
                return
                
            if interactive_id == "menu_ask_doubt" or intent == "ASK_DOUBT" or "doubt" in english_text.lower() or "question" in english_text.lower():
                from whatsapp.llm_service import client
                if client:
                    ans = client.models.generate_content(
                        model='gemini-2.5-flash',
                        contents=f"You are a helpful beekeeping assistant. Answer this farmer's doubt clearly and concisely in english: {english_text}"
                    )
                    await whatsapp_client.send_text(wa_id, f"🤖 *AI Assistant:*\n{ans.text}", current_lang)
                else:
                    await whatsapp_client.send_text(wa_id, "Sorry, AI assistant is unavailable.", current_lang)
                return

    # 5. Route to active flow (FSM)
    if state.startswith("REGISTRATION_"):
        await handle_registration(wa_id, message, state, data, current_lang)
    else:
        # Default fallback
        if not is_registered:
            await handle_registration(wa_id, message, ConversationState.REGISTRATION_NAME, data, current_lang)
        else:
            await handle_main_menu(wa_id, current_lang)

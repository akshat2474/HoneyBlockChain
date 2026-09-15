import asyncio
from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.flows.main_menu import handle_main_menu
from whatsapp.flows.registration import handle_registration
from database import SessionLocal
from models import WhatsAppUser, Beekeeper
from whatsapp.llm_service import analyze_incoming_text, analyze_incoming_audio, translate_outgoing_text


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Main message handler
# ---------------------------------------------------------------------------

async def handle_message(wa_id: str, message: dict):
    msg_type = message.get("type")
    msg_id   = message.get("id")
    original_text = (
        message.get("text", {}).get("body", "").strip()
        if msg_type == "text" else ""
    )

    # -- 0. Deduplication & spam guard ----------------------------------------
    # Bug fix #22: these methods were built but never called
    if msg_id and await redis_service.is_duplicate_message(msg_id):
        print(f"[DEDUP] Skipping duplicate message {msg_id}")
        return
    if await redis_service.is_spamming(wa_id):
        print(f"[SPAM]  Throttling {wa_id}")
        return

    if msg_id:
        await whatsapp_client.mark_as_read(msg_id)

    # -- 1. LLM analysis of incoming message ----------------------------------
    lang         = "en"
    english_text = original_text
    intent       = "UNKNOWN"

    if msg_type == "text" and original_text:
        analysis     = analyze_incoming_text(original_text)
        lang         = analysis.detected_language
        english_text = analysis.translated_english_text
        # Bug fix #2: normalise intent — LLM may return lowercase or spaces
        intent = analysis.intent.upper().replace(" ", "_").strip()
        print(f"[LLM TEXT]  lang={lang} | intent={intent} | text={english_text!r}")

    elif msg_type == "audio":
        media_id = message.get("audio", {}).get("id")
        if media_id:
            try:
                # Bug fix #13: download_media now raises on failure; catch here
                audio_bytes  = await whatsapp_client.download_media(media_id)
                analysis     = analyze_incoming_audio(audio_bytes)
                lang         = analysis.detected_language
                english_text = analysis.translated_english_text
                intent = analysis.intent.upper().replace(" ", "_").strip()
                print(f"[LLM AUDIO] lang={lang} | intent={intent} | text={english_text!r}")
            except Exception as e:
                print(f"Audio processing error: {e}")
                await whatsapp_client.send_text(
                    wa_id,
                    "Sorry, I could not process your voice note. Please send a text message.",
                )
                return

    # -- 2. Session from Redis -------------------------------------------------
    state_data = await redis_service.get_session(wa_id)
    state      = state_data.get("state", ConversationState.IDLE)
    data       = state_data.get("data", {})
    # Inject translated text so flows do not need to re-translate
    data["english_text"] = english_text

    # -- 3. Interactive reply id (button OR list) ------------------------------
    # Bug fix #18: was only checking button_reply; list_reply was silently ignored
    interactive  = message.get("interactive", {})
    interactive_id = (
        interactive.get("button_reply", {}).get("id", "")
        or interactive.get("list_reply",  {}).get("id", "")
    )

    # -- 4. Registration status ------------------------------------------------
    db = SessionLocal()
    try:
        is_registered = (
            db.query(Beekeeper).filter(Beekeeper.phone == wa_id).first() is not None
        )
    finally:
        db.close()

    # -- 5. User language ------------------------------------------------------
    # Bug fix #17: never store "UNKNOWN" as the user language
    safe_lang = lang if lang not in ("", "UNKNOWN") else "en"
    user_meta = get_or_create_user(wa_id, safe_lang)
    if safe_lang not in ("en",) and msg_type in ("text", "audio"):
        update_user_language(wa_id, safe_lang)
    current_lang = user_meta.language if user_meta.language not in ("", "UNKNOWN") else "en"

    # -- 5.5 Global Intercepts - ANY STATE ------------------------------------
    if intent == "CHANGE_LANGUAGE" or "language" in english_text.lower():
        # If the LLM successfully extracted the language they requested
        req_lang = getattr(analysis, "requested_language_code", "").strip().lower()
        if req_lang and len(req_lang) >= 2:
            req_lang = req_lang[:2] # grab 'te', 'hi', etc.
            update_user_language(wa_id, req_lang)
            # Update current session so the success message uses the new language
            current_lang = req_lang
            
            # Map basic codes to names for the success message
            lang_names = {"en": "English", "hi": "Hindi", "bn": "Bengali", "te": "Telugu", "ta": "Tamil", "mr": "Marathi"}
            lang_name = lang_names.get(req_lang, req_lang.upper())
            
            msg = f"✅ Language updated to {lang_name}!\n\nYou can send 'menu' to return to the main options."
            await whatsapp_client.send_text(
                wa_id, translate_outgoing_text(msg, current_lang), current_lang
            )
            # Clear stuck settings state
            if state == ConversationState.SETTINGS_CHOOSE_LANGUAGE:
                await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": current_lang})
            return

        # Prompt for language and move to SETTINGS_CHOOSE_LANGUAGE if they didn't specify one
        await whatsapp_client.send_text(
            wa_id,
            "Which language would you like to use? (Please type the name of the language, e.g., Telugu, Marathi, Hindi)",
            current_lang
        )
        await redis_service.set_session(wa_id, ConversationState.SETTINGS_CHOOSE_LANGUAGE, {"language": current_lang})
        return

    # -- 6. Global intercepts — IDLE / MAIN_MENU -------------------------------
    if state in (ConversationState.IDLE, ConversationState.MAIN_MENU):
        if not is_registered:
            greeting_intents  = ("MAIN_MENU", "REGISTRATION")
            greeting_keywords = ("hi", "hello", "menu", "register", "start")
            if intent in greeting_intents or english_text.lower() in greeting_keywords:
                # Provide a menu for new users instead of jumping straight to registration
                buttons = [
                    {"type": "reply", "reply": {"id": "onboard_register", "title": "Register Now"}},
                    {"type": "reply", "reply": {"id": "onboard_info", "title": "About App"}},
                    {"type": "reply", "reply": {"id": "onboard_doubt", "title": "Ask a Question"}},
                ]
                welcome_text = "👋 Welcome to *HoneyChain*!\n\nWe help beekeepers get fair prices and transparency through the *Pollinator App*. How can I help you today?"
                await whatsapp_client.send_buttons(wa_id, welcome_text, buttons, current_lang)
                await redis_service.set_session(wa_id, ConversationState.ONBOARDING, {})
                return
            else:
                # Bug fix #3: unregistered user free-text was silently dropped
                await whatsapp_client.send_text(
                    wa_id,
                    "Welcome to HoneyChain! Please send *hi* to get started.",
                    current_lang,
                )
            return

        # -- Registered user shortcuts -----------------------------------------
        if intent in ("MAIN_MENU",) or english_text.lower() in ("hi", "hello", "menu"):
            await handle_main_menu(wa_id, current_lang)
            return

        if (
            interactive_id == "menu_transfer"
            or intent == "TRANSFER"
            or "transfer" in english_text.lower()
        ):
            await whatsapp_client.send_text(wa_id, "Please enter the Batch ID you wish to transfer (e.g., BATCH-123):", current_lang)
            await redis_service.set_session(wa_id, ConversationState.TRANSFER_BATCH_ID, data)
            return

        if (
            interactive_id == "menu_batch_status"
            or intent == "VERIFY_BATCH"
            or "batch status" in english_text.lower()
        ):
            await whatsapp_client.send_text(wa_id, "Please enter the Batch ID you wish to verify (e.g., BATCH-123):", current_lang)
            await redis_service.set_session(wa_id, ConversationState.BATCH_STATUS_AWAITING_ID, data)
            return

        if (
            interactive_id == "menu_iot_status"
            or intent == "HIVE_STATUS"
            or "status" in english_text.lower()
        ):
            iot_reply = (
                "Hive Status\n\n"
                "Hive 1: Healthy (35 C, 45% Humidity)\n"
                "Hive 2: Healthy (34 C, 46% Humidity)\n\n"
                "Everything looks good!"
            )
            await whatsapp_client.send_text(wa_id, iot_reply, current_lang)
            return

        if intent == "ASK_DOUBT" or "honeychain" in english_text.lower():
            from whatsapp.llm_service import client as gemini_client, settings
            if gemini_client:
                last_query = data.get("last_query", "")
                last_reply = data.get("last_reply", "")
                context_str = (
                    f"Context of previous message:\nUser asked: '{last_query}'\nYou answered: '{last_reply}'\n\n"
                    if last_query else ""
                )
                prompt = (
                    f"{context_str}You are HoneyChain support. Answer this farmer's query precisely "
                    f"in 1 or 2 short sentences (max 400 characters). "
                    f"If they ask you to repeat or change language, repeat your previous answer.\n"
                    f"User: {english_text}"
                )
                try:
                    # Bug fix: run blocking Gemini call in thread pool
                    ans = await asyncio.to_thread(
                        gemini_client.models.generate_content,
                        model=settings.GEMINI_MODEL,
                        contents=prompt,
                    )
                    reply_text = (ans.text or "").strip() or "I am not sure about that. Please contact support."
                    data["last_query"] = original_text
                    data["last_reply"] = reply_text
                    await redis_service.set_session(wa_id, state, data)
                    await whatsapp_client.send_text(wa_id, f"Bot: {reply_text}", current_lang)
                except Exception as e:
                    print(f"Gemini Q&A error: {e}")
                    await whatsapp_client.send_text(
                        wa_id, "Sorry, I could not process that right now.", current_lang
                    )
            return

        # Robust Fallback: Registered user sent something we don't understand in IDLE state
        await whatsapp_client.send_text(
            wa_id,
            "I'm not sure I understood that. You can send 'menu' to see what I can do, or ask me a question about HoneyChain!",
            current_lang,
        )
        return

    # -- 7. FSM routing --------------------------------------------------------

    if state == ConversationState.ONBOARDING:
        # Handle button selections from the welcome menu
        if interactive_id == "onboard_register":
            await whatsapp_client.send_text(
                wa_id,
                "Let's get you registered!\n\n*Step 1/4:* What is your full name?",
                current_lang
            )
            await redis_service.set_session(wa_id, ConversationState.REGISTRATION_NAME, {})
            return

        if interactive_id == "onboard_info":
            from whatsapp.llm_service import generate_onboarding_response
            # We pass a specific trigger to the LLM for "info"
            response_text, ready = await generate_onboarding_response("info", wa_id)
            await whatsapp_client.send_text(wa_id, response_text, current_lang)
            return
            
        if interactive_id == "onboard_doubt":
            await whatsapp_client.send_text(
                wa_id,
                "Sure! Please type your question, and I will try to answer it.",
                current_lang
            )
            return

        # If user types "hi" or "menu" again, resend the welcome menu
        if intent in ("MAIN_MENU", "REGISTRATION") or english_text.lower() in ("hi", "hello", "menu", "start"):
            buttons = [
                {"type": "reply", "reply": {"id": "onboard_register", "title": "Register Now"}},
                {"type": "reply", "reply": {"id": "onboard_info", "title": "About App"}},
                {"type": "reply", "reply": {"id": "onboard_doubt", "title": "Ask a Question"}},
            ]
            welcome_text = "👋 Welcome to *HoneyChain*!\n\nWe help beekeepers get fair prices and transparency through the *Pollinator App*. How can I help you today?"
            await whatsapp_client.send_buttons(wa_id, welcome_text, buttons, current_lang)
            return

        # If user types something else while in ONBOARDING
        await whatsapp_client.send_text(
            wa_id,
            "Please select an option from the menu above to get started. (Send 'hi' to see the menu again)",
            current_lang
        )
        return

    elif state.startswith("REGISTRATION_"):
        await handle_registration(wa_id, message, state, data, current_lang)

    elif state in (
        ConversationState.MAIN_MENU,
        ConversationState.MENU_HEALTH,
        ConversationState.MENU_MARKET,
        ConversationState.HARVEST_HIVE_NUM,
        ConversationState.HARVEST_WEIGHT,
    ):
        from whatsapp.flows.interactive_menus import handle_interactive_menus
        await handle_interactive_menus(wa_id, message, state, data, current_lang)

    # Bug fix #6: route to the full harvest flow (was dead code before)
    elif state in (
        ConversationState.HARVEST_YARD_ID,
        ConversationState.HARVEST_HIVES,
        ConversationState.HARVEST_VOLUME,
        ConversationState.HARVEST_VARIETAL,
        ConversationState.HARVEST_IMAGE,
    ):
        from whatsapp.flows.harvest import handle_harvest
        await handle_harvest(wa_id, message, state, data, current_lang)

    elif state in (
        ConversationState.TRANSFER_BATCH_ID,
        ConversationState.TRANSFER_BUYER_ID,
        ConversationState.TRANSFER_CONFIRM,
    ):
        from whatsapp.flows.transfer import handle_transfer
        await handle_transfer(wa_id, message, state, data, current_lang)

    # Bug fix #20: BATCH_STATUS was declared but never routed
    elif state == ConversationState.BATCH_STATUS_AWAITING_ID:
        batch_id = english_text.strip().upper()
        if batch_id.startswith("BATCH-"):
            db = SessionLocal()
            try:
                from models import HoneyBatch
                batch = db.query(HoneyBatch).filter(
                    HoneyBatch.batch_id_hash == batch_id
                ).first()
                if batch:
                    reply = (
                        f"Batch Verified\n\n"
                        f"Batch ID: {batch.batch_id_hash}\n"
                        f"Status: {batch.status}\n"
                        f"Current Custodian: +{batch.current_custodian}\n"
                        f"Lab Verified: {'Yes' if batch.lab_verified else 'No'}"
                    )
                else:
                    reply = "Batch not found. Please check the ID and try again."
            except Exception as e:
                print(f"Batch status error: {e}")
                reply = "Could not retrieve batch status. Please try again."
            finally:
                db.close()
        else:
            reply = "Invalid format. Please enter a valid Batch ID (e.g., BATCH-A1B2C3D4)."
        await whatsapp_client.send_text(wa_id, reply, current_lang)
        await redis_service.set_session(wa_id, ConversationState.IDLE, {})

    # Bug fix #20: SETTINGS_CHOOSE_LANGUAGE was declared but never routed
    elif state == ConversationState.SETTINGS_CHOOSE_LANGUAGE:
        from whatsapp.flows.settings import handle_settings
        await handle_settings(wa_id, message, state, data, current_lang)

    # Bug fix #19: DIAGNOSTICS states were declared but never routed
    elif state in (
        ConversationState.DIAGNOSTICS_SELECT,
        ConversationState.DIAGNOSTICS_AWAITING_IMAGE,
        ConversationState.DIAGNOSTICS_AWAITING_AUDIO,
        ConversationState.DIAGNOSTICS_PROCESSING,
    ):
        await whatsapp_client.send_text(
            wa_id,
            "Diagnostics feature is coming soon! Send 'menu' to go back.",
            current_lang,
        )
        await redis_service.set_session(wa_id, ConversationState.IDLE, {})

    else:
        # Unknown / orphaned state — reset gracefully, never go silent
        print(f"[FSM] Unknown state '{state}' for {wa_id}. Resetting to idle.")
        await redis_service.set_session(wa_id, ConversationState.IDLE, {})
        if is_registered:
            await handle_main_menu(wa_id, current_lang)
        else:
            await whatsapp_client.send_text(
                wa_id, "Send 'hi' to get started.", current_lang
            )

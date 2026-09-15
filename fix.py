import os

with open('whatsapp_bot/whatsapp/handler.py', 'r', encoding='utf-8') as f:
    text = f.read()

target = '''        if intent == "CHANGE_LANGUAGE" or "language" in english_text.lower():
            from whatsapp.flows.settings import handle_settings
            # Prompt for language and move to SETTINGS_CHOOSE_LANGUAGE
            buttons = [
                {"type": "reply", "reply": {"id": "lang_en", "title": "English"}},
                {"type": "reply", "reply": {"id": "lang_hi", "title": "Hindi"}},
                {"type": "reply", "reply": {"id": "lang_bn", "title": "Bengali"}},
            ]
            await whatsapp_client.send_buttons(wa_id, "Please select your preferred language:", buttons, current_lang)
            await redis_service.set_session(wa_id, ConversationState.SETTINGS_CHOOSE_LANGUAGE, {"language": current_lang})
            return'''

if target in text:
    text = text.replace(target, '')
    print('Found and removed old block.')
else:
    print('Could not find exact block to remove.')

global_intercept = '''    # -- 5.5 Global Intercepts - ANY STATE ------------------------------------
    if intent == "CHANGE_LANGUAGE" or "language" in english_text.lower():
        # Prompt for language and move to SETTINGS_CHOOSE_LANGUAGE
        buttons = [
            {"type": "reply", "reply": {"id": "lang_en", "title": "English"}},
            {"type": "reply", "reply": {"id": "lang_hi", "title": "Hindi"}},
            {"type": "reply", "reply": {"id": "lang_bn", "title": "Bengali"}},
        ]
        await whatsapp_client.send_buttons(wa_id, "Please select your preferred language:", buttons, current_lang)
        await redis_service.set_session(wa_id, ConversationState.SETTINGS_CHOOSE_LANGUAGE, {"language": current_lang})
        return

    # -- 6. Global intercepts - IDLE / MAIN_MENU -------------------------------'''

text = text.replace('    # -- 6. Global intercepts - IDLE / MAIN_MENU -------------------------------', global_intercept)

with open('whatsapp_bot/whatsapp/handler.py', 'w', encoding='utf-8') as f:
    f.write(text)

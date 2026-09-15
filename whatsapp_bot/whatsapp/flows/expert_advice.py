from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.flows.main_menu import handle_main_menu
from whatsapp.llm_service import client, settings

async def handle_expert_advice(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    interactive_id = message.get("interactive", {}).get("button_reply", {}).get("id", "")
    text = data.get("english_text", "").strip()

    # Handle Back button globally
    if interactive_id == "btn_back" or text.lower() == "back":
        await handle_main_menu(wa_id, lang)
        return

    # 1. Routing from Main Menu to Sub-Menus
    if state == ConversationState.MAIN_MENU:
        if interactive_id == "menu_health_care":
            buttons = [
                {"type": "reply", "reply": {"id": "btn_pests", "title": "?? Pests & Diseases"}},
                {"type": "reply", "reply": {"id": "btn_feeding", "title": "?? Seasons & Feed"}},
                {"type": "reply", "reply": {"id": "btn_back", "title": "?? Back"}}
            ]
            await whatsapp_client.send_buttons(wa_id, "What do you need help with?", buttons, lang)
            await redis_service.set_session(wa_id, ConversationState.MENU_HEALTH, data)
            return

        elif interactive_id == "menu_market_schemes":
            buttons = [
                {"type": "reply", "reply": {"id": "btn_subsidy", "title": "??? Govt Subsidies"}},
                {"type": "reply", "reply": {"id": "btn_harvest", "title": "?? Harvest & Sell"}},
                {"type": "reply", "reply": {"id": "btn_back", "title": "?? Back"}}
            ]
            await whatsapp_client.send_buttons(wa_id, "What are you looking for?", buttons, lang)
            await redis_service.set_session(wa_id, ConversationState.MENU_MARKET, data)
            return

    # 2. Routing from Sub-Menu to Voice Note prompt
    if state in [ConversationState.MENU_HEALTH, ConversationState.MENU_MARKET]:
        category_map = {
            "btn_pests": "Pests & Diseases",
            "btn_feeding": "Feeding & Seasonal Care",
            "btn_subsidy": "Govt Subsidies & KVIC",
            "btn_harvest": "Harvesting & Market Prices"
        }
        
        if interactive_id in category_map:
            category = category_map[interactive_id]
            data["advice_category"] = category
            
            reply_text = f"You selected *{category}*.\n\nPlease type your question or send a Voice Note describing your problem. Our AI expert will help you!"
            await whatsapp_client.send_text(wa_id, reply_text, lang)
            await redis_service.set_session(wa_id, ConversationState.AWAITING_DOUBT_INPUT, data)
        else:
            await whatsapp_client.send_text(wa_id, "Please select a valid option from the menu.", lang)
        return

    # 3. Handling the actual Voice Note / Text Doubt
    if state == ConversationState.AWAITING_DOUBT_INPUT:
        if not text:
            await whatsapp_client.send_text(wa_id, "Please send a text message or voice note.", lang)
            return
            
        category = data.get("advice_category", "General Beekeeping")
        
        if client:
            prompt = f"The user is asking a question specifically about **{category}**. Provide targeted expert advice. Keep it concise, practical, and tailored for a rural Indian beekeeper. User's question: {text}"
            
            try:
                # Use the dynamic model configured in settings
                ans = client.models.generate_content(
                    model=settings.GEMINI_MODEL,
                    contents=prompt
                )
                response_text = f"?? *Expert Advice:*\n{ans.text}"
            except Exception as e:
                response_text = f"Sorry, AI assistant encountered an error: {str(e)}"
            
            buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "?? Main Menu"}}]
            await whatsapp_client.send_buttons(wa_id, response_text, buttons, lang)
        else:
            await whatsapp_client.send_text(wa_id, "Sorry, AI assistant is unavailable.", lang)
            
        # Keep them in the AWAITING_DOUBT_INPUT state so they can ask follow-ups 
        return

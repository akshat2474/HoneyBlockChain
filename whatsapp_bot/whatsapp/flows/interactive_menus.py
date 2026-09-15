from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.flows.main_menu import handle_main_menu

async def handle_interactive_menus(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
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
                {"type": "reply", "reply": {"id": "health_disease", "title": "Check for Diseases"}},
                {"type": "reply", "reply": {"id": "health_queen", "title": "Queen Bee Status"}},
                {"type": "reply", "reply": {"id": "health_condition", "title": "Condition of Hives"}}
            ]
            await whatsapp_client.send_buttons(wa_id, "What health information do you want to check?", buttons, lang)
            await redis_service.set_session(wa_id, ConversationState.MENU_HEALTH, data)
            return

        elif interactive_id == "menu_market_schemes":
            buttons = [
                {"type": "reply", "reply": {"id": "market_subsidy", "title": "Govt Subsidies"}},
                {"type": "reply", "reply": {"id": "market_prices", "title": "Honey Prices"}},
                {"type": "reply", "reply": {"id": "market_register", "title": "Register Harvest"}}
            ]
            await whatsapp_client.send_buttons(wa_id, "What are you looking for?", buttons, lang)
            await redis_service.set_session(wa_id, ConversationState.MENU_MARKET, data)
            return

    # 2. Handling Sub-Menu Clicks (Hardcoded Responses without LLM generation)
    if state == ConversationState.MENU_HEALTH:
        if interactive_id == "health_disease":
            reply = "Our sensors detect a possible Varroa Mite risk in Hive 2 due to abnormal temperature variations. Please inspect the brood frames."
        elif interactive_id == "health_queen":
            reply = "Queen Bee acoustic signatures are strong in all hives. Laying pattern is normal."
        elif interactive_id == "health_condition":
            reply = "Hive 1: Excellent.\nHive 2: Needs attention.\nHive 3: Good.\nHive 4: Needs feeding soon."
        else:
            await whatsapp_client.send_text(wa_id, "Please select an option from the menu.", lang)
            return
            
        buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
        await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
        return

    if state == ConversationState.MENU_MARKET:
        if interactive_id == "market_subsidy":
            reply = "KVIC provides an 80% subsidy for 10 bee boxes under the National Honey Mission. Visit www.kviconline.gov.in or contact your local KVK to apply."
            buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
            await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
            return
        elif interactive_id == "market_prices":
            reply = "Current average farmgate rates:\n\nMustard Honey: ?85/kg\nMultiflora: ?110/kg\nLitchi: ?130/kg"
            buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
            await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
            return
        elif interactive_id == "market_register":
            reply = "Let's register a new harvest.\n\nWhich hive are you harvesting from? (Enter the Hive Number, e.g. 1, 2, 3)"
            await whatsapp_client.send_text(wa_id, reply, lang)
            await redis_service.set_session(wa_id, ConversationState.HARVEST_HIVE_NUM, data)
            return

    # 3. Handling Harvest Registration Flow
    if state == ConversationState.HARVEST_HIVE_NUM:
        digits = ''.join(filter(str.isdigit, text))
        if not digits:
            await whatsapp_client.send_text(wa_id, "Please enter a valid hive number (digits only).", lang)
            return
            
        data["harvest_hive"] = digits
        await whatsapp_client.send_text(wa_id, f"Great. You are harvesting Hive {digits}.\n\nHow many kilograms (kg) of honey did you extract?", lang)
        await redis_service.set_session(wa_id, ConversationState.HARVEST_WEIGHT, data)
        return

    if state == ConversationState.HARVEST_WEIGHT:
        digits = ''.join(filter(lambda c: c.isdigit() or c == '.', text))
        if not digits:
            await whatsapp_client.send_text(wa_id, "Please enter a valid weight in kg.", lang)
            return
            
        reply = f"? Harvest Registered Successfully!\n\nHive Number: {data.get('harvest_hive')}\nWeight: {digits} kg\n\nYour data has been securely saved."
        buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
        await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
        # Reset state to idle or main menu
        await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})
        return


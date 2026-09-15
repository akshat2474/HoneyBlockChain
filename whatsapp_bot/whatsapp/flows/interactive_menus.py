import time
from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.flows.main_menu import handle_main_menu
from database import SessionLocal
from models import HoneyBatch, Beekeeper


async def handle_interactive_menus(
    wa_id: str, message: dict, state: str, data: dict, lang: str = "en"
):
    """
    Handles all button/list-menu interactions and the quick harvest sub-flow
    reachable from Market & Schemes menu.
    """
    # Bug fix #18: was only reading button_reply; list_reply was silently ignored
    interactive = message.get("interactive", {})
    interactive_id = (
        interactive.get("button_reply", {}).get("id", "")
        or interactive.get("list_reply", {}).get("id", "")
    )
    text = data.get("english_text", "").strip()

    # Global back button
    if interactive_id == "btn_back" or text.lower() == "back":
        await handle_main_menu(wa_id, lang)
        return

    # ── 1. MAIN_MENU  ->  sub-menu routing ───────────────────────────────────
    if state == ConversationState.MAIN_MENU:

        # Bug fix #16: menu_box_condition was in the menu but had NO handler
        if interactive_id == "menu_box_condition":
            iot_reply = (
                "Honey Box / IoT Status\n\n"
                "Hive 1: Healthy (35 C, 45% Humidity)\n"
                "Hive 2: Warning - High Temperature (38 C)\n"
                "Hive 3: Healthy (34 C, 47% Humidity)\n\n"
                "Tip: High temp in Hive 2 may indicate swarming. Inspect soon!"
            )
            buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
            await whatsapp_client.send_buttons(wa_id, iot_reply, buttons, lang)
            return

        elif interactive_id == "menu_health_care":
            buttons = [
                {"type": "reply", "reply": {"id": "health_disease",   "title": "Check for Diseases"}},
                {"type": "reply", "reply": {"id": "health_queen",     "title": "Queen Bee Status"}},
                {"type": "reply", "reply": {"id": "health_condition", "title": "Condition of Hives"}},
            ]
            await whatsapp_client.send_buttons(
                wa_id, "What health information do you want to check?", buttons, lang
            )
            await redis_service.set_session(wa_id, ConversationState.MENU_HEALTH, data)
            return

        elif interactive_id == "menu_market_schemes":
            sections = [{
                "title": "Harvest & Market",
                "rows": [
                    {"id": "market_subsidy",      "title": "Govt Subsidies",  "description": "KVIC & National Honey Mission schemes"},
                    {"id": "market_prices",       "title": "Honey Prices",    "description": "Current farmgate rates"},
                    {"id": "market_full_harvest", "title": "Register Harvest","description": "Record a new honey harvest on blockchain"},
                ]
            }]
            await whatsapp_client.send_list(
                wa_id, "🍯 What are you looking for?", sections, lang
            )
            await redis_service.set_session(wa_id, ConversationState.MENU_MARKET, data)
            return

        elif not interactive_id:
            await whatsapp_client.send_text(
                wa_id, "Please tap one of the menu buttons above to continue.", lang
            )
            return

        # Unrecognised button in MAIN_MENU — reset to menu
        await handle_main_menu(wa_id, lang)
        return

    # ── 2. MENU_HEALTH  ->  health sub-menu responses ────────────────────────
    if state == ConversationState.MENU_HEALTH:
        if interactive_id == "health_disease":
            reply = (
                "Our sensors detect a possible Varroa Mite risk in Hive 2 "
                "due to abnormal temperature variations. "
                "Please inspect the brood frames."
            )
        elif interactive_id == "health_queen":
            reply = (
                "Queen Bee acoustic signatures are strong in all hives. "
                "Laying pattern is normal."
            )
        elif interactive_id == "health_condition":
            reply = (
                "Hive Status:\n\n"
                "Hive 1: Excellent\n"
                "Hive 2: Needs attention\n"
                "Hive 3: Good\n"
                "Hive 4: Needs feeding soon"
            )
        else:
            await whatsapp_client.send_text(
                wa_id, "Please tap one of the buttons from the menu above.", lang
            )
            return

        buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
        await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
        return

    # ── 3. MENU_MARKET  ->  market sub-menu responses ────────────────────────
    if state == ConversationState.MENU_MARKET:
        if interactive_id == "market_subsidy":
            reply = (
                "KVIC provides an 80% subsidy for 10 bee boxes under the "
                "National Honey Mission. Visit www.kviconline.gov.in or "
                "contact your local KVK to apply."
            )
            buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
            await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
            return

        elif interactive_id == "market_prices":
            # Bug fix #25: was showing "?" due to encoding corruption; use Unicode escapes
            reply = (
                "Current Average Farmgate Rates:\n\n"
                "Mustard Honey: \u20b985/kg\n"
                "Multiflora: \u20b9110/kg\n"
                "Litchi: \u20b9130/kg"
            )
            buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
            await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
            return

        elif interactive_id == "market_register":
            reply = (
                "Let's register a new harvest.\n\n"
                "Which hive number are you harvesting from? "
                "(Enter a number, e.g. 1, 2, 3)"
            )
            await whatsapp_client.send_text(wa_id, reply, lang)
            await redis_service.set_session(wa_id, ConversationState.HARVEST_HIVE_NUM, data)
            return

        elif interactive_id == "market_full_harvest":
            reply = "Let's start a professional harvest registration.\n\nWhich Yard ID are you harvesting from? (e.g., YARD-001)"
            await whatsapp_client.send_text(wa_id, reply, lang)
            await redis_service.set_session(wa_id, ConversationState.HARVEST_YARD_ID, data)
            return

        else:
            await whatsapp_client.send_text(
                wa_id, "Please tap one of the buttons from the menu above.", lang
            )
            return

    # ── 4. Quick Harvest Flow (from Market menu) ──────────────────────────────

    if state == ConversationState.HARVEST_HIVE_NUM:
        digits = "".join(filter(str.isdigit, text))
        if not digits:
            await whatsapp_client.send_text(
                wa_id, "Please enter a valid hive number (digits only).", lang
            )
            return

        data["harvest_hive"] = digits
        await whatsapp_client.send_text(
            wa_id,
            f"Harvesting from Hive {digits}.\n\n"
            f"How many kilograms (kg) of honey did you extract?",
            lang,
        )
        await redis_service.set_session(wa_id, ConversationState.HARVEST_WEIGHT, data)
        return

    if state == ConversationState.HARVEST_WEIGHT:
        digits = "".join(filter(lambda c: c.isdigit() or c == ".", text))
        if not digits:
            await whatsapp_client.send_text(
                wa_id, "Please enter a valid weight in kg (e.g., 25 or 12.5).", lang
            )
            return
        try:
            weight_kg = float(digits)
        except ValueError:
            await whatsapp_client.send_text(
                wa_id, "Please enter a valid number for the weight.", lang
            )
            return

        # Bug fix #11: harvest said "securely saved" but NEVER wrote to DB
        batch_id_display = f"BATCH-{int(time.time())}"
        db = SessionLocal()
        try:
            bk = db.query(Beekeeper).filter(Beekeeper.phone == wa_id).first()
            batch = HoneyBatch(
                batch_id_hash=batch_id_display,
                beekeeper_id=bk.id if bk else None,
                quantity_grams=int(weight_kg * 1000),  # model stores grams
                honey_type="Unspecified",               # quick harvest has no varietal step
                hives_harvested=int(data.get("harvest_hive", 1)),
                status="PENDING",
                current_custodian=wa_id,
            )
            db.add(batch)
            db.commit()
        except Exception as e:
            print(f"DB Quick Harvest Error: {e}")
            db.rollback()
            await whatsapp_client.send_text(
                wa_id, "Failed to save harvest. Please try again.", lang
            )
            await redis_service.set_session(wa_id, ConversationState.IDLE, {})
            return
        finally:
            db.close()

        # Bug fix #25: "?" replaced with proper checkmark wording
        reply = (
            f"Harvest Registered on HoneyChain!\n\n"
            f"Hive Number: {data.get('harvest_hive', 'N/A')}\n"
            f"Weight: {weight_kg} kg\n"
            f"Batch ID: {batch_id_display}\n\n"
            f"Your data has been securely saved."
        )
        buttons = [{"type": "reply", "reply": {"id": "btn_back", "title": "Back to Menu"}}]
        await whatsapp_client.send_buttons(wa_id, reply, buttons, lang)
        await redis_service.set_session(wa_id, ConversationState.MAIN_MENU, {"language": lang})
        return

from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from database import SessionLocal
from models import Beekeeper, WhatsAppUser


async def handle_registration(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    """
    FSM handler for the beekeeper registration flow.

    States: REGISTRATION_NAME -> REGISTRATION_REGION -> REGISTRATION_CAPACITY
            -> REGISTRATION_PRACTICES  (done -> IDLE + main menu)

    NOTE: The FIRST entry is handled in handler.py (greeting -> prompt for name).
          By the time this function is called with REGISTRATION_NAME, the user
          is RESPONDING to the "what is your name?" prompt.
    """
    # Bug fix #5: use pre-translated english_text from data
    text = data.get("english_text", "").strip()

    # Global cancel shortcut
    if text.lower() == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(
            wa_id, "Registration cancelled. Send 'hi' to return to the menu.", lang
        )
        return

    # ── Step 1: collect name ──────────────────────────────────────────────────
    if state == ConversationState.REGISTRATION_NAME:
        if len(text) < 2:
            await whatsapp_client.send_text(
                wa_id, "Name seems too short. Please enter your full name:", lang
            )
            return

        data["name"]  = text
        data["phone"] = wa_id

        reply = (
            f"Nice to meet you, *{text}*!\n\n"
            f"*(Your phone number +{wa_id} has been noted)*\n\n"
            f"*Step 2/4:* Which State/Region is your primary apiary located in?\n"
            f"(e.g., Punjab, Tamil Nadu)"
        )
        await whatsapp_client.send_text(wa_id, reply, lang)
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_REGION, data)
        return

    # ── Step 2: collect region ────────────────────────────────────────────────
    if state == ConversationState.REGISTRATION_REGION:
        if len(text) < 2:
            await whatsapp_client.send_text(
                wa_id, "Please enter a valid region / state name.", lang
            )
            return

        data["region"] = text
        await whatsapp_client.send_text(
            wa_id,
            "*Step 3/4:* How many beehives do you currently manage? (Enter a number)",
            lang,
        )
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_CAPACITY, data)
        return

    # ── Step 3: collect hive count ────────────────────────────────────────────
    if state == ConversationState.REGISTRATION_CAPACITY:
        digits = "".join(filter(str.isdigit, text))
        if not digits:
            await whatsapp_client.send_text(wa_id, "Please enter a valid number.", lang)
            return

        data["hives"] = int(digits)
        await whatsapp_client.send_text(
            wa_id,
            "*Step 4/4:* Do you use any premium practices?\n"
            "(e.g., Organic, Raw, Treatment-free, or None)",
            lang,
        )
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_PRACTICES, data)
        return

    # ── Step 4: collect practices & save to DB ────────────────────────────────
    if state == ConversationState.REGISTRATION_PRACTICES:
        data["practices"] = text

        db = SessionLocal()
        try:
            bk = Beekeeper(
                name=data["name"],
                phone=data["phone"],
                region=data["region"],
                hives_count=data["hives"],
                practices=data["practices"],
            )
            db.add(bk)
            db.flush()  # assigns bk.id before commit so we can link WhatsAppUser

            # Bug fix #23: link WhatsAppUser.beekeeper_id (was never set before)
            wa_user = (
                db.query(WhatsAppUser)
                .filter(WhatsAppUser.wa_id == wa_id)
                .first()
            )
            if wa_user:
                wa_user.beekeeper_id = bk.id

            db.commit()
        except Exception as e:
            print(f"DB Registration Error: {e}")
            db.rollback()
            # Bug fix #10: DB error was swallowed; success message sent anyway
            await whatsapp_client.send_text(
                wa_id,
                "Registration failed due to a server error. "
                "You may already be registered. "
                "Send 'hi' to check or contact support.",
                lang,
            )
            # Bug fix #4: clear bad state so user is not stuck
            await redis_service.delete_session(wa_id)
            return
        finally:
            db.close()

        # ── Success ───────────────────────────────────────────────────────────
        reply = (
            f"Registration Complete!\n\n"
            f"Name: {data['name']}\n"
            f"Phone: +{data['phone']}\n"
            f"Region: {data['region']}\n"
            f"Hives: {data['hives']}\n"
            f"Practices: {data['practices']}\n\n"
            f"Welcome to HoneyChain!"
        )
        await whatsapp_client.send_text(wa_id, reply, lang)

        # Bug fix #4: clear session so next message does not re-enter registration
        await redis_service.delete_session(wa_id)

        from .main_menu import handle_main_menu
        await handle_main_menu(wa_id, lang)
        return

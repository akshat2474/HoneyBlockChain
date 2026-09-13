from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from database import SessionLocal
from models import Beekeeper

async def handle_registration(wa_id: str, message: dict, state: str, data: dict):
    msg_type = message.get("type")
    text = message.get("text", {}).get("body", "").strip() if msg_type == "text" else ""

    if text.lower() == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(wa_id, "❌ Registration cancelled. Send *hi* to return to the menu.")
        return

    if state == ConversationState.REGISTRATION_NAME:
        if len(text) < 3:
            await whatsapp_client.send_text(wa_id, "⚠️ Name seems too short. Please enter your full name:")
            return
        
        data["name"] = text
        data["phone"] = wa_id # Automatically grab the WhatsApp number they are texting from
        
        await whatsapp_client.send_text(wa_id, f"Nice to meet you, {text}!\n\n*(I have securely registered your phone number as +{wa_id})*\n\n*Step 2/5:* Which State/Region is your primary apiary located in? (e.g., Punjab, Tamil Nadu)")
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_REGION, data)
        return

    if state == ConversationState.REGISTRATION_REGION:
        data["phone"] = text
        await whatsapp_client.send_text(wa_id, "*Step 3/6:* Which State/Region is your primary apiary located in? (e.g., Punjab, Tamil Nadu)")
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_CAPACITY, data)
        return

    if state == ConversationState.REGISTRATION_CAPACITY:
        data["region"] = text
        await whatsapp_client.send_text(wa_id, "*Step 4/6:* How many beehives do you currently manage? (Enter a number)")
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_PRACTICES, data)
        return

    if state == ConversationState.REGISTRATION_PRACTICES:
        if not text.isdigit():
            await whatsapp_client.send_text(wa_id, "⚠️ Please enter a valid number of hives.")
            return
        data["hives"] = int(text)
        await whatsapp_client.send_text(wa_id, "*Step 5/6:* Do you use any premium practices? (e.g., Organic, Raw, Treatment-free, or None)")
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_CONFIRM, data)
        return

    if state == ConversationState.REGISTRATION_CONFIRM:
        data["practices"] = text
        summary = (
            "✅ *Registration Complete!*\n\n"
            f"👤 Name: {data['name']}\n"
            f"📞 Phone: {data['phone']}\n"
            f"📍 Region: {data['region']}\n"
            f"🐝 Hives: {data['hives']}\n"
            f"🌿 Practices: {data['practices']}\n\n"
            "Your profile has been saved to the blockchain registry.\nSend *menu* to return."
        )
        
        # Save to DB
        db = SessionLocal()
        try:
            new_beekeeper = Beekeeper(
                name=data['name'],
                phone=data['phone'],
                region=data['region'],
                hives_count=data['hives'],
                practices=data['practices']
            )
            db.add(new_beekeeper)
            db.commit()
        except Exception as e:
            print("DB Error:", e)
            db.rollback()
        finally:
            db.close()

        await whatsapp_client.send_text(wa_id, summary)
        await redis_service.set_session(wa_id, ConversationState.IDLE)
        return

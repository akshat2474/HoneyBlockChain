from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from database import SessionLocal
from models import Beekeeper

async def handle_registration(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    # We use data.get("english_text") because the LLM already translated the input
    text = data.get("english_text", "").strip()
    
    if text.lower() == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(wa_id, "❌ Registration cancelled. Send 'hi' to return to the menu.", lang)
        return

    if state == ConversationState.REGISTRATION_NAME:
        if len(text) < 2:
            await whatsapp_client.send_text(wa_id, "⚠️ Name seems too short. Please enter your full name:", lang)
            return
        
        data["name"] = text
        data["phone"] = wa_id
        
        reply = f"Nice to meet you, {text}!\n\n*(I have securely registered your phone number as +{wa_id})*\n\n*Step 2/5:* Which State/Region is your primary apiary located in? (e.g., Punjab, Tamil Nadu)"
        await whatsapp_client.send_text(wa_id, reply, lang)
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_REGION, data)
        return

    if state == ConversationState.REGISTRATION_REGION:
        data["region"] = text
        await whatsapp_client.send_text(wa_id, "*Step 3/5:* How many beehives do you currently manage? (Enter a number)", lang)
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_CAPACITY, data)
        return

    if state == ConversationState.REGISTRATION_CAPACITY:
        # We can extract digits if LLM translation left extra words
        digits = ''.join(filter(str.isdigit, text))
        if not digits:
            await whatsapp_client.send_text(wa_id, "⚠️ Please enter a valid number.", lang)
            return
            
        data["hives"] = int(digits)
        await whatsapp_client.send_text(wa_id, "*Step 4/5:* Do you use any premium practices? (e.g., Organic, Raw, Treatment-free, or None)", lang)
        await redis_service.set_session(wa_id, ConversationState.REGISTRATION_PRACTICES, data)
        return

    if state == ConversationState.REGISTRATION_PRACTICES:
        data["practices"] = text
        
        # Save to DB
        db = SessionLocal()
        try:
            bk = Beekeeper(
                name=data["name"],
                phone=data["phone"],
                region=data["region"],
                hives_count=data["hives"],
                practices=data["practices"]
            )
            db.add(bk)
            db.commit()
        except Exception as e:
            print("DB Error:", e)
            db.rollback()
        finally:
            db.close()

        # Reply
        reply = (
            f"✅ *Registration Complete!*\n\n"
            f"👤 Name: {data['name']}\n"
            f"📞 Phone: {data['phone']}\n"
            f"📍 Region: {data['region']}\n"
            f"🐝 Hives: {data['hives']}\n"
            f"🌿 Practices: {data['practices']}\n\n"
            f"Your profile has been saved. Send 'menu' to return."
        )
        await whatsapp_client.send_text(wa_id, reply, lang)
        
        from .main_menu import handle_main_menu
        await handle_main_menu(wa_id, lang)
        return

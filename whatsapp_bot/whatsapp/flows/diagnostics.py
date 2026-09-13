import random
from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState

MOCK_IMAGE_DISEASES = [
    {"name": "Varroa Mite Infestation", "confidence": 87.5, "severity": "HIGH", "treatment": "Apply Oxalic Acid vapor treatment."},
    {"name": "Healthy Colony", "confidence": 95.3, "severity": "NONE", "treatment": "Continue regular inspections."}
]

MOCK_AUDIO_RESULTS = [
    {"name": "Queenless Hive Detected", "confidence": 89.2, "severity": "CRITICAL", "treatment": "Introduce a new mated queen immediately."},
    {"name": "Queenright (Healthy Hum)", "confidence": 92.1, "severity": "NONE", "treatment": "No action needed. Colony is stable."}
]

async def handle_diagnostics(wa_id: str, message: dict, state: str, data: dict):
    msg_type = message.get("type")
    text = message.get("text", {}).get("body", "").lower().strip() if msg_type == "text" else ""

    if text == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(wa_id, "❌ Diagnostics cancelled. Send *hi* to return to the menu.")
        return

    if state == ConversationState.DIAGNOSTICS_SELECT:
        interactive_id = message.get("interactive", {}).get("button_reply", {}).get("id", "")
        
        if interactive_id == "diag_image" or text == "1":
            await whatsapp_client.send_text(wa_id, "📸 *Image Analysis*\n\nPlease send a clear photo of your beehive or honeycomb to check for visible diseases (e.g., Varroa, Foulbrood).\n\nSend *cancel* to abort.")
            await redis_service.set_session(wa_id, ConversationState.DIAGNOSTICS_AWAITING_IMAGE)
        elif interactive_id == "diag_audio" or text == "2":
            await whatsapp_client.send_text(wa_id, "🎤 *Audio Analysis (Queen Check)*\n\nPlease record and send a 5-10 second voice note holding your phone near the entrance of the hive.\n\nSend *cancel* to abort.")
            await redis_service.set_session(wa_id, ConversationState.DIAGNOSTICS_AWAITING_AUDIO)
        else:
            await whatsapp_client.send_buttons(wa_id, "🤖 *AI Hive Diagnostics*\n\nWhat would you like to analyze?", [
                {"type": "reply", "reply": {"id": "diag_image", "title": "📸 Hive Image"}},
                {"type": "reply", "reply": {"id": "diag_audio", "title": "🎤 Hive Audio"}}
            ])
        return

    if state == ConversationState.DIAGNOSTICS_AWAITING_IMAGE:
        if msg_type == "image":
            await whatsapp_client.send_text(wa_id, "🔬 *Analyzing image...*")
            res = random.choice(MOCK_IMAGE_DISEASES)
            reply = f"📊 *Result:* {res['name']}\n🎯 *Confidence:* {res['confidence']}%\n⚠️ *Severity:* {res['severity']}\n💊 *Treatment:* {res['treatment']}\n\nSend *menu* to return."
            await whatsapp_client.send_text(wa_id, reply)
            await redis_service.set_session(wa_id, ConversationState.IDLE)
        else:
            await whatsapp_client.send_text(wa_id, "⚠️ Please send an *image*. Send *cancel* to abort.")
        return

    if state == ConversationState.DIAGNOSTICS_AWAITING_AUDIO:
        if msg_type == "audio":
            await whatsapp_client.send_text(wa_id, "🎶 *Analyzing acoustic signature...*")
            res = random.choice(MOCK_AUDIO_RESULTS)
            reply = f"📊 *Result:* {res['name']}\n🎯 *Confidence:* {res['confidence']}%\n⚠️ *Severity:* {res['severity']}\n💊 *Action:* {res['treatment']}\n\nSend *menu* to return."
            await whatsapp_client.send_text(wa_id, reply)
            await redis_service.set_session(wa_id, ConversationState.IDLE)
        else:
            await whatsapp_client.send_text(wa_id, "⚠️ Please send an *audio voice note*. Send *cancel* to abort.")
        return

import random
from whatsapp.client import whatsapp_client
from whatsapp.fsm import redis_service
from whatsapp.states import ConversationState
from whatsapp.i18n import t

MOCK_IMAGE_DISEASES = [
    {"name": "Varroa Mite Infestation", "confidence": 87.5, "severity": "HIGH", "treatment": "Apply Oxalic Acid vapor treatment."},
    {"name": "Healthy Colony", "confidence": 95.3, "severity": "NONE", "treatment": "Continue regular inspections."}
]

MOCK_AUDIO_RESULTS = [
    {"name": "Queenless Hive Detected", "confidence": 89.2, "severity": "CRITICAL", "treatment": "Introduce a new mated queen immediately."},
    {"name": "Queenright (Healthy Hum)", "confidence": 92.1, "severity": "NONE", "treatment": "No action needed. Colony is stable."}
]

async def handle_diagnostics(wa_id: str, message: dict, state: str, data: dict, lang: str = "en"):
    msg_type = message.get("type")
    text = message.get("text", {}).get("body", "").lower().strip() if msg_type == "text" else ""

    if text == "cancel":
        await redis_service.delete_session(wa_id)
        await whatsapp_client.send_text(wa_id, t(lang, "general.cancelled"))
        return

    if state == ConversationState.DIAGNOSTICS_SELECT:
        interactive_id = message.get("interactive", {}).get("button_reply", {}).get("id", "")
        
        if interactive_id == "diag_image" or text == "1":
            await whatsapp_client.send_text(wa_id, t(lang, "diag.img_prompt"))
            await redis_service.set_session(wa_id, ConversationState.DIAGNOSTICS_AWAITING_IMAGE, data)
        elif interactive_id == "diag_audio" or text == "2":
            await whatsapp_client.send_text(wa_id, t(lang, "diag.aud_prompt"))
            await redis_service.set_session(wa_id, ConversationState.DIAGNOSTICS_AWAITING_AUDIO, data)
        else:
            await whatsapp_client.send_buttons(wa_id, t(lang, "diag.select_prompt"), [
                {"type": "reply", "reply": {"id": "diag_image", "title": t(lang, "diag.opt_image")}},
                {"type": "reply", "reply": {"id": "diag_audio", "title": t(lang, "diag.opt_audio")}}
            ])
        return

    if state == ConversationState.DIAGNOSTICS_AWAITING_IMAGE:
        if msg_type == "image":
            await whatsapp_client.send_text(wa_id, t(lang, "diag.analyzing_img"))
            res = random.choice(MOCK_IMAGE_DISEASES)
            
            reply = t(lang, "diag.result_template").format(
                name=res["name"],
                confidence=res["confidence"],
                severity=res["severity"],
                treatment=res["treatment"]
            )
            
            await whatsapp_client.send_text(wa_id, reply)
            await redis_service.set_session(wa_id, ConversationState.IDLE, data)
        else:
            await whatsapp_client.send_text(wa_id, t(lang, "diag.err_img"))
        return

    if state == ConversationState.DIAGNOSTICS_AWAITING_AUDIO:
        if msg_type == "audio":
            await whatsapp_client.send_text(wa_id, t(lang, "diag.analyzing_aud"))
            res = random.choice(MOCK_AUDIO_RESULTS)
            
            reply = t(lang, "diag.result_template").format(
                name=res["name"],
                confidence=res["confidence"],
                severity=res["severity"],
                treatment=res["treatment"]
            )
            
            await whatsapp_client.send_text(wa_id, reply)
            await redis_service.set_session(wa_id, ConversationState.IDLE, data)
        else:
            await whatsapp_client.send_text(wa_id, t(lang, "diag.err_aud"))
        return

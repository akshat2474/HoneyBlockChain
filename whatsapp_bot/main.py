from fastapi import FastAPI, Request, HTTPException, BackgroundTasks, Query
from fastapi.responses import PlainTextResponse, JSONResponse
import hmac
import hashlib
import json
from config import settings
from whatsapp.handler import handle_message

app = FastAPI(title="HoneyChain WhatsApp Bot (Python)")

@app.get("/")
def read_root():
    return {"status": "ok", "service": "HoneyChain Bot (FastAPI)"}

@app.get("/webhook/whatsapp")
async def verify_webhook(
    hub_mode: str = Query(None, alias="hub.mode"),
    hub_verify_token: str = Query(None, alias="hub.verify_token"),
    hub_challenge: str = Query(None, alias="hub.challenge")
):
    if hub_mode == "subscribe" and hub_verify_token == settings.WHATSAPP_VERIFY_TOKEN:
        return PlainTextResponse(hub_challenge)
    raise HTTPException(status_code=403, detail="Verification failed")

@app.post("/webhook/whatsapp")
async def receive_message(request: Request, background_tasks: BackgroundTasks):
    body_bytes = await request.body()
    signature = request.headers.get("x-hub-signature-256", "")
    
    # HMAC verification
    if settings.WHATSAPP_APP_SECRET:
        expected_sig = hmac.new(
            settings.WHATSAPP_APP_SECRET.encode('utf-8'),
            body_bytes,
            hashlib.sha256
        ).hexdigest()
        
        if not hmac.compare_digest(f"sha256={expected_sig}", signature):
            print("Invalid signature")
            return JSONResponse({"status": "ok"})
            
    payload = json.loads(body_bytes)
    
    # Extract entries
    if "entry" in payload:
        for entry in payload["entry"]:
            for change in entry.get("changes", []):
                value = change.get("value", {})
                messages = value.get("messages", [])
                for message in messages:
                    # Run handler in background so Meta gets 200 OK instantly
                    background_tasks.add_task(handle_message, message)
                    
    return JSONResponse({"status": "ok"})

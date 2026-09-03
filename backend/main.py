import json
import logging
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

# Set up simple logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="IDR Backend")

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info(f"Client connected: {websocket.client}")
    try:
        while True:
            # Receive data from Flutter
            data = await websocket.receive_text()
            
            # Parse it to validate format
            try:
                payload = json.loads(data)
                
                # For Phase 2, we just echo back the received data with a status flag
                # to prove two-way communication works perfectly.
                response = {
                    "status": "success",
                    "message": "Data received and parsed by Python",
                    "echo": payload
                }
                
                # Send response back to Flutter
                await websocket.send_text(json.dumps(response))
                
            except json.JSONDecodeError:
                logger.error("Failed to parse JSON")
                await websocket.send_text(json.dumps({"error": "Invalid JSON"}))
                
    except WebSocketDisconnect:
        logger.info("Client disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")

if __name__ == "__main__":
    import uvicorn
    # Bind to 0.0.0.0 so the phone on the local Wi-Fi can connect to it
    uvicorn.run(app, host="0.0.0.0", port=8000)

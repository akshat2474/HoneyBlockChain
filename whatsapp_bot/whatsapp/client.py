import httpx
from config import settings

class WhatsAppClient:
    def __init__(self):
        self.base_url = f"https://graph.facebook.com/{settings.WHATSAPP_API_VERSION}/{settings.WHATSAPP_PHONE_NUMBER_ID}/messages"
        self.headers = {
            "Authorization": f"Bearer {settings.WHATSAPP_ACCESS_TOKEN}",
            "Content-Type": "application/json"
        }

    async def _send(self, payload: dict):
        async with httpx.AsyncClient() as client:
            response = await client.post(self.base_url, json=payload, headers=self.headers)
            try:
                response.raise_for_status()
                return response.json()
            except httpx.HTTPStatusError as e:
                print(f"WhatsApp API Error: {e.response.text}")
                return None

    async def send_text(self, to: str, text: str):
        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "text",
            "text": {"body": text}
        })

    async def send_buttons(self, to: str, text: str, buttons: list):
        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "interactive",
            "interactive": {
                "type": "button",
                "body": {"text": text},
                "action": {
                    "buttons": buttons
                }
            }
        })

    async def send_list(self, to: str, text: str, sections: list):
        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "interactive",
            "interactive": {
                "type": "list",
                "body": {"text": text},
                "action": {
                    "button": "Select Option",
                    "sections": sections
                }
            }
        })

    async def mark_as_read(self, message_id: str):
        async with httpx.AsyncClient() as client:
            await client.post(
                self.base_url,
                json={"messaging_product": "whatsapp", "status": "read", "message_id": message_id},
                headers=self.headers
            )

whatsapp_client = WhatsAppClient()

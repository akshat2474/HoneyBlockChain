import httpx
from config import settings

class WhatsAppClient:
    def __init__(self):
        self.base_url = f"https://graph.facebook.com/{settings.WHATSAPP_API_VERSION}/{settings.WHATSAPP_PHONE_NUMBER_ID}/messages"
        self.headers = {
            "Authorization": f"Bearer {settings.WHATSAPP_ACCESS_TOKEN}",
            "Content-Type": "application/json"
        }
        self.media_headers = {
            "Authorization": f"Bearer {settings.WHATSAPP_ACCESS_TOKEN}"
        }

    async def download_media(self, media_id: str) -> bytes:
        async with httpx.AsyncClient() as client:
            # 1. Get Media URL
            res = await client.get(f"https://graph.facebook.com/{settings.WHATSAPP_API_VERSION}/{media_id}", headers=self.media_headers)
            res.raise_for_status()
            media_url = res.json().get("url")
            
            # 2. Download Binary Data
            media_res = await client.get(media_url, headers=self.media_headers)
            media_res.raise_for_status()
            return media_res.content

    async def _send(self, payload: dict):
        async with httpx.AsyncClient() as client:
            response = await client.post(self.base_url, json=payload, headers=self.headers)
            try:
                response.raise_for_status()
                return response.json()
            except httpx.HTTPStatusError as e:
                print(f"WhatsApp API Error: {e.response.text}")
                return None

    async def send_text(self, to: str, text: str, lang: str = "en"):
        from whatsapp.llm_service import translate_outgoing_text
        translated = translate_outgoing_text(text, lang)
        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "text",
            "text": {"body": translated}
        })

    async def send_buttons(self, to: str, text: str, buttons: list, lang: str = "en"):
        from whatsapp.llm_service import translate_outgoing_text
        translated = translate_outgoing_text(text, lang)
        
        # We also translate the button titles
        translated_buttons = []
        for btn in buttons:
            new_btn = btn.copy()
            new_btn["reply"]["title"] = translate_outgoing_text(btn["reply"]["title"], lang)
            translated_buttons.append(new_btn)

        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "interactive",
            "interactive": {
                "type": "button",
                "body": {"text": translated},
                "action": {
                    "buttons": translated_buttons
                }
            }
        })

    async def send_list(self, to: str, text: str, sections: list, lang: str = "en"):
        from whatsapp.llm_service import translate_outgoing_text
        translated_text = translate_outgoing_text(text, lang)
        
        translated_sections = []
        for sec in sections:
            new_sec = sec.copy()
            new_sec["title"] = translate_outgoing_text(sec["title"], lang)
            new_rows = []
            for row in sec["rows"]:
                new_row = row.copy()
                new_row["title"] = translate_outgoing_text(row["title"], lang)
                new_row["description"] = translate_outgoing_text(row.get("description", ""), lang)
                new_rows.append(new_row)
            new_sec["rows"] = new_rows
            translated_sections.append(new_sec)

        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "interactive",
            "interactive": {
                "type": "list",
                "body": {"text": translated_text},
                "action": {
                    "button": translate_outgoing_text("Menu", lang),
                    "sections": translated_sections
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

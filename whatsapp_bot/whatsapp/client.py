import asyncio
import httpx
from config import settings


class WhatsAppClient:
    def __init__(self):
        self.base_url = (
            f"https://graph.facebook.com/{settings.WHATSAPP_API_VERSION}"
            f"/{settings.WHATSAPP_PHONE_NUMBER_ID}/messages"
        )
        self.headers = {
            "Authorization": f"Bearer {settings.WHATSAPP_ACCESS_TOKEN}",
            "Content-Type": "application/json",
        }
        self.media_headers = {
            "Authorization": f"Bearer {settings.WHATSAPP_ACCESS_TOKEN}"
        }

    async def download_media(self, media_id: str) -> bytes:
        """Download binary media from WhatsApp. Raises on failure so caller can handle."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Step 1: resolve media URL
            res = await client.get(
                f"https://graph.facebook.com/{settings.WHATSAPP_API_VERSION}/{media_id}",
                headers=self.media_headers,
            )
            res.raise_for_status()
            media_url = res.json().get("url")
            if not media_url:
                raise ValueError(f"No media URL returned for media_id={media_id}")
            # Step 2: download binary
            media_res = await client.get(media_url, headers=self.media_headers)
            media_res.raise_for_status()
            return media_res.content

    async def _send(self, payload: dict):
        """POST a message payload to the WhatsApp API. Logs errors, never raises."""
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(self.base_url, json=payload, headers=self.headers)
                response.raise_for_status()
                return response.json()
        except httpx.HTTPStatusError as e:
            print(f"WhatsApp API HTTP Error {e.response.status_code}: {e.response.text}")
            return None
        except Exception as e:
            print(f"WhatsApp API Error: {e}")
            return None

    # ------------------------------------------------------------------
    # Bug fix #15: use asyncio.to_thread so synchronous LLM translation
    # calls do NOT block the asyncio event loop.
    # ------------------------------------------------------------------

    async def _translate(self, text: str, lang: str) -> str:
        """Run synchronous translate_outgoing_text in a thread pool."""
        from whatsapp.llm_service import translate_outgoing_text
        return await asyncio.to_thread(translate_outgoing_text, text, lang)

    async def send_text(self, to: str, text: str, lang: str = "en"):
        translated = await self._translate(text, lang)
        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "text",
            "text": {"body": translated},
        })

    async def send_buttons(self, to: str, text: str, buttons: list, lang: str = "en"):
        translated_body = await self._translate(text, lang)

        translated_buttons = []
        for btn in buttons:
            translated_title = await self._translate(btn["reply"]["title"], lang)
            new_btn = {
                "type": btn["type"],
                "reply": {
                    "id": btn["reply"]["id"],
                    "title": translated_title[:20],  # WhatsApp limit is 20 chars
                },
            }
            translated_buttons.append(new_btn)

        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "interactive",
            "interactive": {
                "type": "button",
                "body": {"text": translated_body},
                "action": {"buttons": translated_buttons},
            },
        })

    async def send_list(self, to: str, text: str, sections: list, lang: str = "en"):
        translated_text = await self._translate(text, lang)

        translated_sections = []
        for sec in sections:
            new_sec = sec.copy()
            translated_sec_title = await self._translate(sec["title"], lang)
            new_sec["title"] = translated_sec_title[:24]  # WhatsApp limit is 24 chars
            new_rows = []
            for row in sec["rows"]:
                new_row = row.copy()
                translated_row_title = await self._translate(row["title"], lang)
                translated_row_desc = await self._translate(row.get("description", ""), lang)
                new_row["title"] = translated_row_title[:24]
                new_row["description"] = translated_row_desc[:72]
                new_rows.append(new_row)
            new_sec["rows"] = new_rows
            translated_sections.append(new_sec)

        translated_menu_btn = await self._translate("Menu", lang)
        return await self._send({
            "messaging_product": "whatsapp",
            "to": to,
            "type": "interactive",
            "interactive": {
                "type": "list",
                "body": {"text": translated_text},
                "action": {
                    "button": translated_menu_btn[:20],
                    "sections": translated_sections,
                },
            },
        })

    async def mark_as_read(self, message_id: str):
        """Mark a message as read (blue ticks). Non-critical — logs errors, never raises."""
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                await client.post(
                    self.base_url,
                    json={
                        "messaging_product": "whatsapp",
                        "status": "read",
                        "message_id": message_id,
                    },
                    headers=self.headers,
                )
        except Exception as e:
            # Non-critical: failing to show blue ticks should not block message handling
            print(f"mark_as_read failed for {message_id}: {e}")


whatsapp_client = WhatsAppClient()

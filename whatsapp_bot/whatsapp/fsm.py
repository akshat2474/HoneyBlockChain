import json
from redis.asyncio import Redis
from config import settings

class RedisService:
    def __init__(self):
        # protocol=2 prevents 'unknown command HELLO' on older Windows Redis servers
        self.redis = Redis.from_url(settings.REDIS_URL, decode_responses=True, protocol=2)

    async def get_session(self, wa_id: str) -> dict:
        data = await self.redis.get(f"wa:session:{wa_id}")
        if data:
            return json.loads(data)
        return {"state": "IDLE", "data": {}}

    async def set_session(self, wa_id: str, state: str, data: dict = None):
        if data is None:
            data = {}
        await self.redis.set(f"wa:session:{wa_id}", json.dumps({"state": state, "data": data}), ex=86400)

    async def delete_session(self, wa_id: str):
        await self.redis.delete(f"wa:session:{wa_id}")

    async def is_duplicate_message(self, msg_id: str) -> bool:
        if not msg_id:
            return False
        # nx=True means only set if it does not exist
        result = await self.redis.set(f"wa:msg:{msg_id}", "1", ex=86400, nx=True)
        return result is None

    async def is_spamming(self, wa_id: str) -> bool:
        result = await self.redis.set(f"wa:cooldown:{wa_id}", "1", ex=2, nx=True)
        return result is None

redis_service = RedisService()

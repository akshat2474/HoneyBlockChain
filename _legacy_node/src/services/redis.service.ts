import Redis from 'ioredis';
import { config } from '../config';
import { logger } from '../utils/logger';

const redis = new Redis(config.REDIS_URL, {
  maxRetriesPerRequest: 3,
});

redis.on('error', (err) => {
  logger.error({ err }, 'Redis connection error');
});

redis.on('connect', () => {
  logger.info('Connected to Redis');
});

export const redisService = {
  async getSession(waId: string) {
    const data = await redis.get(`session:${waId}`);
    return data ? JSON.parse(data) : null;
  },
  
  async setSession(waId: string, state: string, data: any = {}) {
    await redis.set(`session:${waId}`, JSON.stringify({ state, data }), 'EX', 86400); // 24h TTL
  },
  
  async deleteSession(waId: string) {
    await redis.del(`session:${waId}`);
  },

  // Prevents processing the exact same Meta webhook twice
  async isDuplicateMessage(msgId: string): Promise<boolean> {
    if (!msgId) return false;
    // SET NX = only set if it doesn't exist. EX 86400 = expire in 24 hours.
    const result = await redis.set(`msg:${msgId}`, '1', 'EX', 86400, 'NX');
    return result === null; // If null, the key already existed -> it's a duplicate
  },

  // Prevents a user from spamming messages (1.5 second cooldown)
  async isSpamming(waId: string): Promise<boolean> {
    // 2 second cooldown lock
    const result = await redis.set(`cooldown:${waId}`, '1', 'EX', 2, 'NX');
    return result === null; // If null, user is on cooldown -> they are spamming
  }
};

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
  }
};

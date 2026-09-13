import { z } from 'zod';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const envSchema = z.object({
  // Server
  PORT: z.coerce.number().default(3001),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // Database
  DATABASE_URL: z.string().default('file:./dev.db'),

  // Blockchain
  AMOY_RPC_URL: z.string().default('https://rpc-amoy.polygon.technology'),
  PRIVATE_KEY: z.string().default(''),
  CONTRACT_ADDRESS: z.string().default(''),
  PINATA_JWT: z.string().default(''),

  // WhatsApp
  WHATSAPP_ACCESS_TOKEN: z.string().default(''),
  WHATSAPP_PHONE_NUMBER_ID: z.string().default(''),
  WHATSAPP_BUSINESS_ACCOUNT_ID: z.string().default(''),
  WHATSAPP_VERIFY_TOKEN: z.string().default('honeychain_verify_2026'),
  WHATSAPP_APP_SECRET: z.string().default(''),
  WHATSAPP_API_VERSION: z.string().default('v21.0'),

  // Redis
  REDIS_URL: z.string().default('redis://localhost:6379/0'),

  // ML Service
  ML_SERVICE_URL: z.string().default('http://localhost:8000'),
  GEMINI_API_KEY: z.string().default(''),

  // Logging
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('debug'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:', parsed.error.format());
  process.exit(1);
}

export const config = parsed.data;
export type Config = typeof config;

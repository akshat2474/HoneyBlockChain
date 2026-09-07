import crypto from 'crypto';
import { config } from '../config';

export function verifyWebhookSignature(payload: string, signature: string): boolean {
  if (!config.WHATSAPP_APP_SECRET) return true; // Skip if no secret configured
  const expected = crypto.createHmac('sha256', config.WHATSAPP_APP_SECRET).update(payload).digest('hex');
  const expectedSignature = `sha256=${expected}`;
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
}

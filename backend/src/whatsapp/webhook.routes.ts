import { Router } from 'express';
import { config } from '../config';
import { verifyWebhookSignature } from './webhook.validator';
import { handleMessage } from './handler';
import { logger } from '../utils/logger';

export const webhookRoutes = Router();

webhookRoutes.get('/webhook/whatsapp', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === config.WHATSAPP_VERIFY_TOKEN) {
    logger.info('Webhook verified successfully');
    res.status(200).send(challenge);
  } else {
    res.sendStatus(403);
  }
});

webhookRoutes.post('/webhook/whatsapp', (req, res) => {
  const signature = req.headers['x-hub-signature-256'] as string;
  const rawBody = req.body;

  logger.info('📩 Webhook POST received');

  if (signature && config.WHATSAPP_APP_SECRET) {
    if (!verifyWebhookSignature(rawBody.toString('utf8'), signature)) {
      logger.error('Invalid signature');
      return res.sendStatus(401);
    }
  }

  let parsedBody: any;
  try {
    parsedBody = JSON.parse(rawBody.toString('utf8'));
  } catch (e) {
    logger.error('Failed to parse raw body');
    return res.sendStatus(400);
  }

  // Always respond 200 immediately
  res.sendStatus(200);

  // Debug: log the full payload
  logger.info({ payload: JSON.stringify(parsedBody).substring(0, 500) }, '📋 Webhook payload');

  if (parsedBody.object) {
    const entry = parsedBody.entry?.[0];
    const changes = entry?.changes?.[0];
    const value = changes?.value;

    if (value?.messages?.[0]) {
      const message = value.messages[0];
      const waId = message.from;
      logger.info({ waId, type: message.type, text: message.text?.body }, '💬 Message received');

      handleMessage(waId, message).catch(err => {
        logger.error({ err }, 'Error handling message');
      });
    } else if (value?.statuses) {
      logger.info({ status: value.statuses[0]?.status }, '📊 Status update (not a message)');
    } else {
      logger.info('⚠️ Webhook received but no messages found in payload');
    }
  }
});

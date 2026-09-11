import { whatsappClient } from './client';
import { FSM } from './fsm';
import { ConversationState } from './states';
import { handleMainMenu } from './flows/mainMenu.flow';
import { handleDiseaseDetection } from './flows/diseaseDetection.flow';
import { handleRegistration } from './flows/registration.flow';
import { handleBatchStatus } from './flows/batchStatus.flow';
import { handleHiveStatus } from './flows/hiveStatus.flow';
import { handleHealthReport } from './flows/healthReport.flow';
import { redisService } from '../services/redis.service';
import { logger } from '../utils/logger';

export async function handleMessage(waId: string, message: any) {
  // 1. Prevent duplicate processing of the same Meta webhook
  if (await redisService.isDuplicateMessage(message.id)) {
    logger.info({ msgId: message.id }, '♻️ Ignored duplicate webhook message');
    return;
  }

  // 2. Prevent user spam (rapid-fire messages causing delayed bombardments)
  if (await redisService.isSpamming(waId)) {
    logger.warn({ waId }, '⚠️ Ignored message due to spam cooldown');
    return;
  }

  const { state, data } = await FSM.getState(waId);
  await whatsappClient.markAsRead(message.id);

  // Extract text from different message types
  const text = message.text?.body?.toLowerCase().trim() || '';
  const interactiveId = message.interactive?.list_reply?.id
    || message.interactive?.button_reply?.id
    || '';

  logger.info({ waId, state, text, interactiveId, type: message.type }, '🔀 Routing message');

  // Reset keywords — go to menu
  if (['hi', 'hello', 'menu', 'start', '0'].includes(text)) {
    // Prevent bombarding the user with the menu if they just asked for it multiple times
    if (state !== ConversationState.MAIN_MENU) {
      await handleMainMenu(waId);
    }
    return;
  }

  // Handle menu selections (interactive list replies)
  if (state === ConversationState.MAIN_MENU || state === ConversationState.IDLE) {
    switch (interactiveId) {
      case 'menu_disease':
        await whatsappClient.sendText(waId, '📸 *Bee Disease Detection*\n\nPlease send a clear photo of your beehive or honeycomb. Our AI will analyze it for common diseases like:\n\n• Varroa Mite\n• American Foulbrood\n• European Foulbrood\n• Nosema\n• Chalk Brood');
        await FSM.setState(waId, ConversationState.DISEASE_AWAITING_IMAGE);
        return;

      case 'menu_register':
        await whatsappClient.sendText(waId, '📋 *Beekeeper Registration*\n\nLet\'s get you registered on HoneyBlockChain!\n\n*Step 1/5:* What is your full name?');
        await FSM.setState(waId, ConversationState.REGISTRATION_NAME, {});
        return;

      case 'menu_hive':
        await handleHiveStatus(waId, message, ConversationState.HIVE_STATUS, data);
        return;

      case 'menu_batch':
        await whatsappClient.sendText(waId, '🍯 *Batch Verification*\n\nEnter the Batch ID printed on your honey jar label (e.g. HB-2026-001):');
        await FSM.setState(waId, ConversationState.BATCH_STATUS_AWAITING_ID);
        return;

      case 'menu_health':
        await handleHealthReport(waId, message, ConversationState.HEALTH_REPORT, data);
        return;

      case 'menu_lang':
        await whatsappClient.sendText(waId, '🌐 Language selection coming soon!\n\nCurrently supported: English\nComing soon: हिन्दी, தமிழ், తెలుగు');
        await FSM.clearState(waId);
        return;

      default:
        // If they type a number instead of using the list
        if (text === '1') { await handleMessage(waId, { ...message, interactive: { list_reply: { id: 'menu_disease' } } }); return; }
        if (text === '2') { await handleMessage(waId, { ...message, interactive: { list_reply: { id: 'menu_register' } } }); return; }
        if (text === '3') { await handleMessage(waId, { ...message, interactive: { list_reply: { id: 'menu_hive' } } }); return; }
        if (text === '4') { await handleMessage(waId, { ...message, interactive: { list_reply: { id: 'menu_batch' } } }); return; }
        if (text === '5') { await handleMessage(waId, { ...message, interactive: { list_reply: { id: 'menu_health' } } }); return; }
        if (text === '6') { await handleMessage(waId, { ...message, interactive: { list_reply: { id: 'menu_lang' } } }); return; }

        // Show menu again if unrecognized
        await handleMainMenu(waId);
        return;
    }
  }

  // Route to active flow
  if (state.startsWith('DISEASE_')) {
    await handleDiseaseDetection(waId, message, state, data);
  } else if (state.startsWith('REGISTRATION_')) {
    await handleRegistration(waId, message, state, data);
  } else if (state.startsWith('HIVE_') || state === ConversationState.HIVE_STATUS) {
    await handleHiveStatus(waId, message, state, data);
  } else if (state === ConversationState.BATCH_STATUS_AWAITING_ID) {
    await handleBatchStatus(waId, message, state, data);
  } else if (state === ConversationState.HEALTH_REPORT) {
    await handleHealthReport(waId, message, state, data);
  } else {
    await handleMainMenu(waId);
  }
}

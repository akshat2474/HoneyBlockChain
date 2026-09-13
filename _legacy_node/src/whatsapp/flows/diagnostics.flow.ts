import { whatsappClient } from '../client';
import { FSM } from '../fsm';
import { ConversationState } from '../states';
import { logger } from '../../utils/logger';

// Mock responses for Image (Disease)
const MOCK_IMAGE_DISEASES = [
  {
    name: 'Varroa Mite Infestation',
    confidence: 87.5,
    severity: 'HIGH',
    description: 'Varroa destructor mites detected on bee bodies and brood cells.',
    treatment: 'Apply Oxalic Acid vapor treatment (2g per hive).',
  },
  {
    name: 'Healthy Colony',
    confidence: 95.3,
    severity: 'NONE',
    description: 'No visible signs of disease or pest infestation detected.',
    treatment: 'Continue regular inspections.',
  },
];

// Mock responses for Audio (Queenless)
const MOCK_AUDIO_RESULTS = [
  {
    name: 'Queenless Hive Detected',
    confidence: 89.2,
    severity: 'CRITICAL',
    description: 'Acoustic analysis shows high-frequency "roaring" (moaning) typical of a queenless colony.',
    treatment: 'Introduce a new mated queen or combine with a strong queenright colony immediately.',
  },
  {
    name: 'Queenright (Healthy Hum)',
    confidence: 92.1,
    severity: 'NONE',
    description: 'Acoustic analysis shows a steady, low-frequency hum typical of a healthy colony with a laying queen.',
    treatment: 'No action needed. Colony is stable.',
  },
];

export async function handleDiagnostics(waId: string, message: any, state: string, data: any) {
  const text = message.text?.body?.toLowerCase().trim();

  // Handle Cancel
  if (text === 'cancel') {
    await FSM.clearState(waId);
    await whatsappClient.sendText(waId, '❌ Diagnostics cancelled. Send *hi* to return to the menu.');
    return;
  }

  // State 1: Choose mode
  if (state === ConversationState.DIAGNOSTICS_SELECT) {
    const interactiveId = message.interactive?.list_reply?.id || message.interactive?.button_reply?.id;
    
    if (interactiveId === 'diag_image' || text === '1') {
      await whatsappClient.sendText(waId, '📸 *Image Analysis*\n\nPlease send a clear photo of your beehive or honeycomb to check for visible diseases (e.g., Varroa, Foulbrood).\n\nSend *cancel* to abort.');
      await FSM.setState(waId, ConversationState.DIAGNOSTICS_AWAITING_IMAGE);
    } else if (interactiveId === 'diag_audio' || text === '2') {
      await whatsappClient.sendText(waId, '🎤 *Audio Analysis (Queen Check)*\n\nPlease record and send a 5-10 second voice note holding your phone near the entrance of the hive.\n\nOur AI will analyze the acoustic signature to determine if the hive is Queenless.\n\nSend *cancel* to abort.');
      await FSM.setState(waId, ConversationState.DIAGNOSTICS_AWAITING_AUDIO);
    } else {
      await whatsappClient.sendButtons(waId, '🤖 *AI Hive Diagnostics*\n\nWhat would you like to analyze?', [
        { type: 'reply', reply: { id: 'diag_image', title: '📸 Hive Image' } },
        { type: 'reply', reply: { id: 'diag_audio', title: '🎤 Hive Audio' } },
      ]);
    }
    return;
  }

  // State 2: Awaiting Image
  if (state === ConversationState.DIAGNOSTICS_AWAITING_IMAGE) {
    if (message.type === 'image') {
      await whatsappClient.sendText(waId, '🔬 *Analyzing image...*');
      await new Promise(resolve => setTimeout(resolve, 2000));
      const result = MOCK_IMAGE_DISEASES[Math.floor(Math.random() * MOCK_IMAGE_DISEASES.length)];
      
      let response = `🔬 *Image Analysis Report*\n\n`
        + `📊 *Result:* ${result.name}\n`
        + `🎯 *Confidence:* ${result.confidence}%\n`
        + `⚠️ *Severity:* ${result.severity}\n\n`
        + `📝 *Description:*\n${result.description}\n\n`
        + `💊 *Treatment:*\n${result.treatment}`;
        
      await whatsappClient.sendText(waId, response);
      await followUpButtons(waId, data);
    } else {
      await whatsappClient.sendText(waId, '⚠️ Please send a *photo* (image file). Send *cancel* to abort.');
    }
    return;
  }

  // State 3: Awaiting Audio
  if (state === ConversationState.DIAGNOSTICS_AWAITING_AUDIO) {
    if (message.type === 'audio') {
      await whatsappClient.sendText(waId, '🎶 *Analyzing acoustic signature...*');
      await new Promise(resolve => setTimeout(resolve, 2000));
      const result = MOCK_AUDIO_RESULTS[Math.floor(Math.random() * MOCK_AUDIO_RESULTS.length)];
      
      let response = `🎶 *Audio Analysis Report*\n\n`
        + `📊 *Result:* ${result.name}\n`
        + `🎯 *Confidence:* ${result.confidence}%\n`
        + `⚠️ *Severity:* ${result.severity}\n\n`
        + `📝 *Description:*\n${result.description}\n\n`
        + `💊 *Action:*\n${result.treatment}`;
        
      await whatsappClient.sendText(waId, response);
      await followUpButtons(waId, data);
    } else {
      await whatsappClient.sendText(waId, '⚠️ Please send an *audio voice note*. Hold the mic icon in WhatsApp to record. Send *cancel* to abort.');
    }
    return;
  }
  
  // State 4: Follow up handling
  if (state === ConversationState.DIAGNOSTICS_PROCESSING) {
    const buttonId = message.interactive?.button_reply?.id;
    if (buttonId === 'diag_another') {
      await FSM.setState(waId, ConversationState.DIAGNOSTICS_SELECT);
      await handleDiagnostics(waId, message, ConversationState.DIAGNOSTICS_SELECT, data);
    } else {
      await FSM.clearState(waId);
      const { handleMainMenu } = require('./mainMenu.flow');
      await handleMainMenu(waId);
    }
  }
}

async function followUpButtons(waId: string, data: any) {
  await whatsappClient.sendButtons(waId, 'What would you like to do next?', [
    { type: 'reply', reply: { id: 'diag_another', title: '🤖 Run Another Test' } },
    { type: 'reply', reply: { id: 'diag_menu', title: '📋 Main Menu' } },
  ]);
  await FSM.setState(waId, ConversationState.DIAGNOSTICS_PROCESSING, data);
}

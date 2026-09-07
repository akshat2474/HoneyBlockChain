import { whatsappClient } from '../client';
import { FSM } from '../fsm';
import { ConversationState } from '../states';
import { logger } from '../../utils/logger';

// Hardcoded disease detection results for demo
const MOCK_DISEASES = [
  {
    name: 'Varroa Mite Infestation',
    confidence: 87.5,
    severity: 'HIGH',
    description: 'Varroa destructor mites detected on bee bodies and brood cells.',
    symptoms: [
      'Deformed wings on emerging bees',
      'Reddish-brown spots on bee bodies',
      'Reduced colony population',
    ],
    treatment: [
      '🧪 Apply Oxalic Acid vapor treatment (2g per hive)',
      '🌿 Use Thymol-based strips (Apiguard)',
      '🔄 Perform drone brood removal every 21 days',
      '📅 Schedule treatment in autumn before winter cluster',
    ],
    prevention: 'Regular monitoring with sticky boards. Maintain strong colonies. Requeen annually.',
  },
  {
    name: 'American Foulbrood (AFB)',
    confidence: 92.1,
    severity: 'CRITICAL',
    description: 'Paenibacillus larvae spores detected in brood pattern.',
    symptoms: [
      'Sunken, greasy-looking cappings',
      'Ropy brown larval remains (matchstick test positive)',
      'Foul odor from infected frames',
    ],
    treatment: [
      '🔥 BURN all infected frames and equipment (legally required)',
      '📢 Report to nearest apiary inspector immediately',
      '🚫 Do NOT transfer frames to healthy colonies',
      '🧹 Scorch hive bodies with blowtorch before reuse',
    ],
    prevention: 'Never feed unknown honey. Inspect regularly. Maintain clean equipment.',
  },
  {
    name: 'Healthy Colony',
    confidence: 95.3,
    severity: 'NONE',
    description: 'No visible signs of disease or pest infestation detected.',
    symptoms: [],
    treatment: [],
    prevention: 'Continue regular inspections every 2 weeks. Maintain proper ventilation and nutrition.',
  },
];

export async function handleDiseaseDetection(waId: string, message: any, state: string, data: any) {
  if (state === ConversationState.DISEASE_AWAITING_IMAGE) {
    if (message.type === 'image') {
      await whatsappClient.sendText(waId, '🔬 *Analyzing your image...*\n\nOur AI is examining the photo for signs of common bee diseases. This usually takes a few seconds...');

      // Simulate processing delay
      await new Promise(resolve => setTimeout(resolve, 2000));

      // Pick a random mock result
      const result = MOCK_DISEASES[Math.floor(Math.random() * MOCK_DISEASES.length)];

      let response = `🔬 *Disease Detection Report*\n\n`;
      response += `📊 *Result:* ${result.name}\n`;
      response += `🎯 *Confidence:* ${result.confidence}%\n`;
      response += `⚠️ *Severity:* ${result.severity}\n\n`;
      response += `📝 *Description:*\n${result.description}\n`;

      if (result.symptoms.length > 0) {
        response += `\n🔍 *Symptoms Found:*\n`;
        result.symptoms.forEach(s => { response += `  • ${s}\n`; });
      }

      if (result.treatment.length > 0) {
        response += `\n💊 *Recommended Treatment:*\n`;
        result.treatment.forEach(t => { response += `  ${t}\n`; });
      }

      response += `\n🛡️ *Prevention:*\n${result.prevention}`;
      response += `\n\n_Note: This is an AI-assisted analysis. Always consult a certified apiary expert for confirmation._`;

      await whatsappClient.sendText(waId, response);

      // Log the report
      logger.info({ waId, disease: result.name, confidence: result.confidence }, '🔬 Disease detection completed');

      await whatsappClient.sendButtons(waId, 'What would you like to do next?', [
        { type: 'reply', reply: { id: 'disease_another', title: '📸 Analyze Another' } },
        { type: 'reply', reply: { id: 'disease_menu', title: '📋 Main Menu' } },
      ]);
      await FSM.setState(waId, ConversationState.DISEASE_PROCESSING, data);

    } else {
      await whatsappClient.sendText(waId,
        '📸 Please send a *photo* of your beehive or honeycomb.\n\n'
        + '💡 *Tips for best results:*\n'
        + '  • Good lighting (daylight preferred)\n'
        + '  • Clear, close-up shot of the comb\n'
        + '  • Include both brood and honey areas\n'
        + '  • Avoid blurry images\n\n'
        + 'Send *cancel* to go back to menu.'
      );
    }
  } else if (state === ConversationState.DISEASE_PROCESSING) {
    const buttonId = message.interactive?.button_reply?.id || '';
    if (buttonId === 'disease_another') {
      await whatsappClient.sendText(waId, '📸 Send another photo for analysis:');
      await FSM.setState(waId, ConversationState.DISEASE_AWAITING_IMAGE);
    } else {
      await FSM.clearState(waId);
      const { handleMainMenu } = require('./mainMenu.flow');
      await handleMainMenu(waId);
    }
  }
}

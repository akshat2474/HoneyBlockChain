import { whatsappClient } from '../client';
import { FSM } from '../fsm';
import { ConversationState } from '../states';
import { logger } from '../../utils/logger';

export async function handleMainMenu(waId: string) {
  const sections = [
    {
      title: 'HoneyBlockChain Services',
      rows: [
        { id: 'menu_register', title: '📋 Register Profile', description: 'Join as a Beekeeper' },
        { id: 'menu_diagnostics', title: '🤖 AI Diagnostics', description: 'Check Hive Health (Audio/Image)' },
        { id: 'menu_hive', title: '📊 My Hives', description: 'Check IoT status & alerts' },
        { id: 'menu_batch', title: '🍯 Verify Honey', description: 'Trace batch on Blockchain' },
        { id: 'menu_health', title: '📈 Apiary Report', description: 'Overall health & market prices' },
        { id: 'menu_lang', title: '🌐 Change Language', description: 'English / हिन्दी' },
      ],
    },
  ];

  await whatsappClient.sendList(
    waId,
    '👋 *Welcome to HoneyBlockChain!*\n\nI am your AI Beekeeper Assistant. Please select an option below:',
    sections
  );

  await FSM.setState(waId, ConversationState.MAIN_MENU);
  logger.info({ waId }, '📋 Sent main menu');
}

import { whatsappClient } from '../client';
import { FSM } from '../fsm';
import { ConversationState } from '../states';

export async function handleMainMenu(waId: string) {
  const sections = [
    {
      title: 'Main Menu',
      rows: [
        { id: 'menu_disease', title: '🐝 Disease Detection', description: 'Send hive photo for analysis' },
        { id: 'menu_register', title: '📋 Register as Beekeeper' },
        { id: 'menu_hive', title: '📊 Hive Status' },
        { id: 'menu_batch', title: '🍯 Batch Status / Verify' },
        { id: 'menu_health', title: '📈 Health Report' },
        { id: 'menu_lang', title: '🌐 Change Language' }
      ]
    }
  ];

  await whatsappClient.sendList(waId, 'Welcome to HoneyBlockChain! Please select an option:', sections);
  await FSM.setState(waId, ConversationState.MAIN_MENU);
}

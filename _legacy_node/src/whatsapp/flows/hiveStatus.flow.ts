import { whatsappClient } from '../client';
import { FSM } from '../fsm';
import { ConversationState } from '../states';

// Hardcoded hive data for demo
const MOCK_HIVES = [
  {
    id: 'HIVE-001',
    location: 'Dehradun, Uttarakhand',
    beeSpecies: 'Apis cerana indica',
    colonyStrength: 'Strong (8/10 frames)',
    queenStatus: '✅ Queen Present, Laying Well',
    lastInspection: '2026-09-01',
    honeyStores: '12.5 kg (Above Average)',
    broodPattern: 'Compact & Healthy',
    temperature: '34.2°C',
    humidity: '62%',
    alerts: [],
  },
  {
    id: 'HIVE-002',
    location: 'Chamoli, Uttarakhand',
    beeSpecies: 'Apis mellifera',
    colonyStrength: 'Medium (5/10 frames)',
    queenStatus: '⚠️ Queen Cells Spotted — Possible Swarming',
    lastInspection: '2026-09-03',
    honeyStores: '8.2 kg (Average)',
    broodPattern: 'Slightly Spotty',
    temperature: '35.8°C',
    humidity: '58%',
    alerts: ['⚠️ Swarming risk — add super or split colony'],
  },
  {
    id: 'HIVE-003',
    location: 'Nainital, Uttarakhand',
    beeSpecies: 'Apis cerana indica',
    colonyStrength: 'Weak (3/10 frames)',
    queenStatus: '❌ Queenless — Needs Requeening',
    lastInspection: '2026-09-05',
    honeyStores: '3.1 kg (Low)',
    broodPattern: 'Drone Laying Workers Detected',
    temperature: '33.5°C',
    humidity: '70%',
    alerts: ['🚨 Queenless colony — introduce mated queen ASAP', '⚠️ Low honey stores — consider sugar syrup feeding'],
  },
];

export async function handleHiveStatus(waId: string, message: any, state: string, data: any) {
  if (state === ConversationState.HIVE_STATUS) {
    // Show list of hives
    const sections = [
      {
        title: 'Your Hives',
        rows: MOCK_HIVES.map(h => ({
          id: `hive_${h.id}`,
          title: h.id,
          description: `${h.location} — ${h.colonyStrength}`,
        })),
      },
    ];

    await whatsappClient.sendList(waId, '📊 *Your Hive Dashboard*\n\nSelect a hive to view detailed status:', sections);
    await FSM.setState(waId, ConversationState.HIVE_SELECT, data);

  } else if (state === ConversationState.HIVE_SELECT) {
    const selectedId = message.interactive?.list_reply?.id || '';
    const hiveIdMatch = selectedId.replace('hive_', '');
    const hive = MOCK_HIVES.find(h => h.id === hiveIdMatch);

    if (!hive) {
      await whatsappClient.sendText(waId, '⚠️ Hive not found. Please select from the list.');
      await FSM.setState(waId, ConversationState.HIVE_STATUS, data);
      await handleHiveStatus(waId, message, ConversationState.HIVE_STATUS, data);
      return;
    }

    let response = `📊 *Hive Status: ${hive.id}*\n\n`;
    response += `📍 Location: *${hive.location}*\n`;
    response += `🐝 Species: *${hive.beeSpecies}*\n`;
    response += `💪 Colony Strength: *${hive.colonyStrength}*\n`;
    response += `👑 Queen: ${hive.queenStatus}\n`;
    response += `📅 Last Inspection: *${hive.lastInspection}*\n\n`;
    response += `🍯 Honey Stores: *${hive.honeyStores}*\n`;
    response += `🥚 Brood Pattern: *${hive.broodPattern}*\n\n`;
    response += `🌡️ Temperature: *${hive.temperature}*\n`;
    response += `💧 Humidity: *${hive.humidity}*\n`;

    if (hive.alerts.length > 0) {
      response += `\n🚨 *Alerts:*\n`;
      hive.alerts.forEach(a => { response += `  ${a}\n`; });
    } else {
      response += `\n✅ No alerts — hive is healthy!`;
    }

    await whatsappClient.sendText(waId, response);

    await whatsappClient.sendButtons(waId, 'What next?', [
      { type: 'reply', reply: { id: 'hive_another', title: '📊 View Another Hive' } },
      { type: 'reply', reply: { id: 'hive_menu', title: '📋 Main Menu' } },
    ]);
    await FSM.setState(waId, ConversationState.HIVE_STATUS, data);

    // Handle follow-up buttons inline
  } else {
    const buttonId = message.interactive?.button_reply?.id || '';
    if (buttonId === 'hive_another') {
      await handleHiveStatus(waId, message, ConversationState.HIVE_STATUS, data);
    } else {
      await FSM.clearState(waId);
      const { handleMainMenu } = require('./mainMenu.flow');
      await handleMainMenu(waId);
    }
  }
}

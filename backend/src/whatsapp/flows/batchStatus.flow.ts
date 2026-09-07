import { whatsappClient } from '../client';
import { FSM } from '../fsm';
import { ConversationState } from '../states';

// Hardcoded batch data for demo
const MOCK_BATCHES: Record<string, any> = {
  'HB-2026-001': {
    id: 'HB-2026-001',
    honeyType: 'Litchi Honey',
    quantity: '5000g',
    beekeeper: 'Ramesh Kumar',
    region: 'Dehradun, Uttarakhand',
    harvestDate: '2026-08-15',
    status: 'Lab Verified ✅',
    labVerified: true,
    labReport: 'Moisture: 18.2% | HMF: 25mg/kg | Diastase: 12 DN',
    txHash: '0x8a7f...3b2c',
    currentCustodian: 'District Honey Center, Dehradun',
    journey: [
      '🐝 Aug 15 — Harvested by Ramesh Kumar',
      '🏭 Aug 18 — Processed at Uttarakhand Honey Co-op',
      '🔬 Aug 22 — Lab tested at FSSAI Lab, Dehradun',
      '✅ Aug 25 — Lab Verified (Grade A)',
      '🚛 Sep 01 — Shipped to District Honey Center',
    ],
  },
  'HB-2026-002': {
    id: 'HB-2026-002',
    honeyType: 'Wild Forest Honey',
    quantity: '3200g',
    beekeeper: 'Geeta Devi',
    region: 'Chamoli, Uttarakhand',
    harvestDate: '2026-08-20',
    status: 'In Transit 🚛',
    labVerified: true,
    labReport: 'Moisture: 17.8% | HMF: 18mg/kg | Diastase: 15 DN',
    txHash: '0x4c2e...9f1a',
    currentCustodian: 'KVIC Collection Center, Chamoli',
    journey: [
      '🐝 Aug 20 — Harvested by Geeta Devi',
      '🏭 Aug 23 — Processed at Chamoli Bee Co-op',
      '🔬 Aug 27 — Lab tested at State Honey Lab',
      '✅ Aug 30 — Lab Verified (Grade A+)',
      '🚛 Sep 05 — In Transit to Retail',
    ],
  },
};

export async function handleBatchStatus(waId: string, message: any, state: string, data: any) {
  const text = message.text?.body?.trim().toUpperCase() || '';

  if (text === 'CANCEL') {
    await FSM.clearState(waId);
    await whatsappClient.sendText(waId, 'Cancelled. Send *hi* for menu.');
    return;
  }

  const batch = MOCK_BATCHES[text];

  if (!batch) {
    // Check if it looks like a batch ID format
    if (text.startsWith('HB-')) {
      await whatsappClient.sendText(waId,
        `❌ Batch *${text}* not found in our records.\n\n`
        + `This could mean:\n`
        + `• The batch hasn't been registered yet\n`
        + `• The ID was entered incorrectly\n\n`
        + `Try: *HB-2026-001* or *HB-2026-002* (demo batches)\n\n`
        + `Send another Batch ID or *cancel* to go back.`
      );
    } else {
      await whatsappClient.sendText(waId,
        `⚠️ Please enter a valid Batch ID.\n\nFormat: *HB-YYYY-XXX*\n\nTry: *HB-2026-001* (demo)\n\nSend *cancel* to go back.`
      );
    }
    return;
  }

  let response = `🍯 *Batch Verification Report*\n`;
  response += `━━━━━━━━━━━━━━━━━━━\n\n`;
  response += `🆔 Batch: *${batch.id}*\n`;
  response += `🍯 Type: *${batch.honeyType}*\n`;
  response += `⚖️ Quantity: *${batch.quantity}*\n`;
  response += `👤 Beekeeper: *${batch.beekeeper}*\n`;
  response += `📍 Region: *${batch.region}*\n`;
  response += `📅 Harvest: *${batch.harvestDate}*\n`;
  response += `📊 Status: *${batch.status}*\n\n`;

  if (batch.labVerified) {
    response += `🔬 *Lab Report:*\n  ${batch.labReport}\n\n`;
  }

  response += `🔗 *Blockchain:*\n  Tx: ${batch.txHash}\n`;
  response += `📦 Custodian: *${batch.currentCustodian}*\n\n`;

  response += `📜 *Supply Chain Journey:*\n`;
  batch.journey.forEach((step: string) => {
    response += `  ${step}\n`;
  });

  response += `\n✅ _This batch is verified on Polygon blockchain_`;

  await whatsappClient.sendText(waId, response);
  await FSM.clearState(waId);

  await whatsappClient.sendButtons(waId, 'What next?', [
    { type: 'reply', reply: { id: 'batch_another', title: '🍯 Check Another' } },
    { type: 'reply', reply: { id: 'batch_menu', title: '📋 Main Menu' } },
  ]);
}

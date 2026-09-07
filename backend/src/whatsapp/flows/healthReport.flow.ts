import { whatsappClient } from '../client';
import { FSM } from '../fsm';
import { ConversationState } from '../states';

export async function handleHealthReport(waId: string, message: any, state: string, data: any) {
  const report = `📈 *Apiary Health Report*\n`
    + `📅 Period: September 2026\n`
    + `━━━━━━━━━━━━━━━━━━━\n\n`
    + `🏠 *Colony Overview*\n`
    + `  Total Hives: *3*\n`
    + `  Healthy: *1* 🟢\n`
    + `  Needs Attention: *1* 🟡\n`
    + `  Critical: *1* 🔴\n\n`
    + `🍯 *Production Summary*\n`
    + `  Total Honey: *23.8 kg*\n`
    + `  Avg per Hive: *7.9 kg*\n`
    + `  vs Last Month: *+12.3%* 📈\n\n`
    + `🐝 *Colony Health Metrics*\n`
    + `  Avg Colony Strength: *5.3/10*\n`
    + `  Queen Present: *2/3 hives*\n`
    + `  Varroa Mite Index: *2.1%* (Safe <3%)\n`
    + `  Avg Temperature: *34.5°C* ✅\n`
    + `  Avg Humidity: *63%* ✅\n\n`
    + `⚠️ *Action Items*\n`
    + `  1. Requeen HIVE-003 (queenless)\n`
    + `  2. Monitor HIVE-002 for swarming\n`
    + `  3. Feed HIVE-003 sugar syrup\n\n`
    + `💰 *Market Prices (Uttarakhand)*\n`
    + `  Raw Multifloral: ₹450/kg\n`
    + `  Organic Certified: ₹650/kg\n`
    + `  Litchi Honey: ₹550/kg\n`
    + `  Wild Forest: ₹800/kg\n\n`
    + `_Next scheduled inspection: 15 Sep 2026_`;

  await whatsappClient.sendText(waId, report);

  await whatsappClient.sendButtons(waId, 'Need anything else?', [
    { type: 'reply', reply: { id: 'health_hive', title: '📊 View Hive Details' } },
    { type: 'reply', reply: { id: 'health_menu', title: '📋 Main Menu' } },
  ]);

  await FSM.clearState(waId);
}

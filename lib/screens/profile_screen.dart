import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../widgets/honey_art.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(28), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Beekeeper identity', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6), const Text('Your verified profile on the Honey Chain network.', style: TextStyle(color: HoneyColors.muted)),
    const SizedBox(height: 28),
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: HoneyColors.cream, borderRadius: BorderRadius.circular(22)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 76, height: 76, decoration: const BoxDecoration(color: HoneyColors.gold, shape: BoxShape.circle), child: const Center(child: HoneyArt(type: HoneyArtType.bee, size: 58))), const SizedBox(width: 18), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Priya Patil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('KVIC-certified beekeeper • Satara cluster', style: TextStyle(color: HoneyColors.muted)), SizedBox(height: 12), _Pill(text: 'Identity verified', icon: Icons.verified_rounded)]))])),
    const SizedBox(height: 21),
    Wrap(spacing: 18, runSpacing: 18, children: const [
      _InfoBox(label: 'KVIC REGISTRATION', value: 'KVIC-MH-289431', icon: Icons.badge_outlined),
      _InfoBox(label: 'WALLET ADDRESS', value: '0x92f1...8eB3', icon: Icons.account_balance_wallet_outlined),
      _InfoBox(label: 'BEEKEEPER CLUSTER', value: 'Satara Valley • 48 members', icon: Icons.groups_outlined),
    ]),
    const SizedBox(height: 24),
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: HoneyColors.cream)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Traceability promise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('Every harvest connected to this identity can be traced, tested and independently verified by the people who enjoy it.', style: TextStyle(color: HoneyColors.muted, height: 1.5))]))
  ]))));
}
class _Pill extends StatelessWidget { const _Pill({required this.text, required this.icon}); final String text; final IconData icon; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: HoneyColors.goldDark, size: 16), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))])); }
class _InfoBox extends StatelessWidget { const _InfoBox({required this.label, required this.value, required this.icon}); final String label,value; final IconData icon; @override Widget build(BuildContext context) => Container(width: 260, padding: const EdgeInsets.all(19), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: HoneyColors.cream), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: HoneyColors.goldDark), const SizedBox(height: 14), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: HoneyColors.muted, letterSpacing: .7)), const SizedBox(height: 5), Text(value, style: const TextStyle(fontWeight: FontWeight.w900))])); }

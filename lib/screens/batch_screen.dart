import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

class BatchScreen extends StatelessWidget {
  const BatchScreen({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(28), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1080), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Blockchain Batch Management', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Every jar gets a permanent, trustworthy history.', style: TextStyle(color: HoneyColors.muted))])), ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Create batch'), style: HoneyTheme.goldButton)]),
    const SizedBox(height: 28),
    Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: HoneyColors.cream)), child: Column(children: [
      Container(padding: const EdgeInsets.all(17), decoration: const BoxDecoration(color: HoneyColors.offWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(18))), child: const Row(children: [Expanded(flex: 2, child: Text('BATCH ID', style: _Head())), Expanded(child: Text('HARVEST', style: _Head())), Expanded(child: Text('STATUS', style: _Head())), Expanded(child: Text('QR', style: _Head()))])),
      const _BatchRow(id: 'HC-KVIC-2026-084', date: '06 Sep 2026', status: 'Certified'),
      const _BatchRow(id: 'HC-KVIC-2026-083', date: '04 Sep 2026', status: 'On-chain'),
      const _BatchRow(id: 'HC-KVIC-2026-082', date: '30 Aug 2026', status: 'Certified'),
    ])),
    const SizedBox(height: 25),
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: HoneyColors.cream, borderRadius: BorderRadius.circular(18)), child: const Row(children: [Icon(Icons.lock_outline_rounded, color: HoneyColors.goldDark), SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Immutable batch records', style: TextStyle(fontWeight: FontWeight.w900)), Text('Certificates and sensor logs are pinned to IPFS and verified on Polygon.', style: TextStyle(color: HoneyColors.muted))]))]))
  ]))));
}
class _Head extends TextStyle { const _Head() : super(fontSize: 11, fontWeight: FontWeight.w900, color: HoneyColors.muted, letterSpacing: .6); }
class _BatchRow extends StatelessWidget { const _BatchRow({required this.id, required this.date, required this.status}); final String id,date,status; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HoneyColors.cream))), child: Row(children: [Expanded(flex: 2, child: Text(id, style: const TextStyle(fontWeight: FontWeight.w900))), Expanded(child: Text(date)), Expanded(child: Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: HoneyColors.cream, borderRadius: BorderRadius.circular(20)), child: Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))))), const Icon(Icons.qr_code_2_rounded, color: HoneyColors.goldDark)])); }

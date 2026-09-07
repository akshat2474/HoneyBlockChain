import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../widgets/honey_art.dart';

class QrVerifyScreen extends StatefulWidget {
  const QrVerifyScreen({super.key});
  @override
  State<QrVerifyScreen> createState() => _QrVerifyScreenState();
}

class _QrVerifyScreenState extends State<QrVerifyScreen> {
  bool verified = false;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                const HoneyArt(type: HoneyArtType.jar, size: 105),
                const SizedBox(height: 13),
                const Text('Verify your honey', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Enter the jar ID, or scan its QR code to see its journey.', textAlign: TextAlign.center, style: TextStyle(color: HoneyColors.muted)),
                const SizedBox(height: 26),
                Row(children: [
                  const Expanded(child: TextField(decoration: InputDecoration(hintText: 'e.g. HC-KVIC-2026-084', prefixIcon: Icon(Icons.qr_code_scanner_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15)), borderSide: BorderSide(color: HoneyColors.cream))))),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: () => setState(() => verified = true), style: HoneyTheme.goldButton, child: const Text('Verify')),
                ]),
                const SizedBox(height: 28),
                if (verified) const _CertificateCard() else const _ScanPrompt(),
                const SizedBox(height: 25),
                Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: const Color(0xFFFFEEE8), borderRadius: BorderRadius.circular(15)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: HoneyColors.warning), SizedBox(width: 11), Expanded(child: Text('If a jar shows no verified record, do not purchase it. Report suspected counterfeits to your nearest KVIC centre.', style: TextStyle(color: HoneyColors.brown, height: 1.4))) ])),
              ]),
            ),
          ),
        ),
      );
}

class _ScanPrompt extends StatelessWidget { const _ScanPrompt(); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40), decoration: BoxDecoration(color: HoneyColors.offWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: HoneyColors.cream)), child: const Column(children: [Icon(Icons.document_scanner_outlined, size: 44, color: HoneyColors.goldDark), SizedBox(height: 10), Text('Ready when you are', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('Your verified certificate will appear here.', style: TextStyle(color: HoneyColors.muted))])); }
class _CertificateCard extends StatelessWidget { const _CertificateCard(); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: HoneyColors.gold, width: 2), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 16)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.verified_rounded, color: HoneyColors.goldDark, size: 30), SizedBox(width: 10), Expanded(child: Text('Authentic KVIC Honey', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))]), const SizedBox(height: 17), const Wrap(spacing: 35, runSpacing: 12, children: [_CertificateItem('Batch', 'HC-KVIC-2026-084'), _CertificateItem('Origin', 'Satara, Maharashtra'), _CertificateItem('Harvested', '06 Sep 2026'), _CertificateItem('Lab test', 'NABL #MHL-2901')]), const SizedBox(height: 18), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: HoneyColors.cream, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.link, color: HoneyColors.goldDark), SizedBox(width: 8), Expanded(child: Text('Polygon transaction verified • IPFS certificate pinned', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)))]))])); }
class _CertificateItem extends StatelessWidget { const _CertificateItem(this.label, this.value); final String label,value; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: HoneyColors.muted, letterSpacing: .8)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]); }

import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Good morning, Priya', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('Your KVIC hives are healthy and producing beautifully.', style: TextStyle(color: HoneyColors.muted)),
              const SizedBox(height: 28),
              Wrap(spacing: 16, runSpacing: 16, children: const [
                _Metric(label: 'Active Hives', value: '24', icon: Icons.hive_outlined),
                _Metric(label: 'Today’s Yield', value: '18.6 kg', icon: Icons.water_drop_outlined),
                _Metric(label: 'Health Score', value: '98%', icon: Icons.favorite_outline),
                _Metric(label: 'On-chain Batches', value: '37', icon: Icons.link_rounded),
              ]),
              const SizedBox(height: 28),
              LayoutBuilder(builder: (context, box) => Wrap(spacing: 20, runSpacing: 20, children: [
                _Panel(width: box.maxWidth > 760 ? 630 : box.maxWidth, title: 'Hive activity', child: const _Chart()),
                _Panel(width: box.maxWidth > 760 ? 400 : box.maxWidth, title: 'AI hive watch', child: const _AlertList()),
              ])),
            ]),
          ),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        width: 245,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: HoneyColors.cream, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: HoneyColors.gold, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text(label, style: const TextStyle(color: HoneyColors.muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.width, required this.title, required this.child});
  final double width;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(width: width, padding: const EdgeInsets.all(23), decoration: BoxDecoration(border: Border.all(color: HoneyColors.cream), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 20), child]));
}

class _Chart extends StatelessWidget {
  const _Chart();
  @override
  Widget build(BuildContext context) => SizedBox(height: 190, width: double.infinity, child: CustomPaint(painter: _ChartPainter()));
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = HoneyColors.cream..strokeWidth = 1;
    for (var i = 1; i < 4; i++) { canvas.drawLine(Offset(0, size.height * i / 4), Offset(size.width, size.height * i / 4), grid); }
    final line = Paint()..color = HoneyColors.gold..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(0, size.height * .72)..cubicTo(size.width * .12, size.height * .35, size.width * .19, size.height * .70, size.width * .32, size.height * .45)..cubicTo(size.width * .48, size.height * .17, size.width * .57, size.height * .67, size.width * .68, size.height * .39)..cubicTo(size.width * .80, size.height * .10, size.width * .90, size.height * .34, size.width, size.height * .17);
    canvas.drawPath(path, line);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlertList extends StatelessWidget {
  const _AlertList();
  @override
  Widget build(BuildContext context) => const Column(children: [
    _Alert(icon: Icons.check_circle_outline, title: 'Hive 04 is thriving', subtitle: 'Health score climbed to 99%'),
    Divider(height: 27),
    _Alert(icon: Icons.auto_awesome_outlined, title: 'Yield forecast ready', subtitle: '14% increase expected this week'),
    Divider(height: 27),
    _Alert(icon: Icons.shield_outlined, title: 'No disease detected', subtitle: 'Last scan: 12 minutes ago'),
  ]);
}
class _Alert extends StatelessWidget { const _Alert({required this.icon, required this.title, required this.subtitle}); final IconData icon; final String title, subtitle; @override Widget build(BuildContext context) => Row(children: [Icon(icon, color: HoneyColors.goldDark), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontSize: 12, color: HoneyColors.muted))]))]); }

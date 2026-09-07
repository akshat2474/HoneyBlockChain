import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../widgets/honey_art.dart';
import '../widgets/process_card.dart';
import '../widgets/stat_tile.dart';
import '../widgets/wave_clipper.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final mobile = box.maxWidth < 680;
        return SingleChildScrollView(
          child: Column(children: [
            _Hero(mobile: mobile, onVerify: () => onNavigate(2)),
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                Text('How Honey Chain Works', textAlign: TextAlign.center, style: HoneyTheme.logo.copyWith(fontSize: mobile ? 29 : 36)),
                const SizedBox(height: 9),
                const Text('A clear, tamper-proof trail from the hive to your home.', textAlign: TextAlign.center, style: TextStyle(color: HoneyColors.muted)),
                const SizedBox(height: 34),
                SizedBox(
                  width: 920,
                  child: Stack(children: [
                    if (!mobile)
                      Positioned.fill(
                        child: CustomPaint(painter: _FlightPathPainter()),
                      ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 40,
                      runSpacing: 20,
                      children: const [
                        ProcessCard(step: 'STEP ONE', title: 'Harvest & Log', art: HoneyArtType.bee, description: 'Beekeeper logs each KVIC hive batch alongside IoT sensor data on Polygon.'),
                        ProcessCard(step: 'STEP TWO', title: 'Lab Quality Audit', art: HoneyArtType.hive, description: 'NABL-accredited tests and certificates are uploaded safely to IPFS.'),
                        ProcessCard(step: 'STEP THREE', title: 'Consumer QR Scan', art: HoneyArtType.jar, description: 'Scan the jar to verify its origin, beekeeper identity and certification.'),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 34),
                Wrap(alignment: WrapAlignment.center, spacing: 13, runSpacing: 12, children: [
                  OutlinedButton(onPressed: () => onNavigate(0), style: OutlinedButton.styleFrom(foregroundColor: HoneyColors.brown, side: const BorderSide(color: HoneyColors.gold, width: 2), padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 15), shape: const StadiumBorder()), child: const Text('Explore Dashboard')),
                  ElevatedButton(onPressed: () {}, style: HoneyTheme.goldButton, child: const Text('Learn About Blockchain')),
                ]),
                const SizedBox(height: 58),
              ]),
            ),
            const _TelemetrySection(),
            const _Footer(),
          ]),
        );
      });
}

class _Hero extends StatelessWidget {
  const _Hero({required this.mobile, required this.onVerify});
  final bool mobile;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: mobile ? 600 : 430,
        child: Stack(children: [
          Container(color: HoneyColors.gold),
          Align(alignment: Alignment.bottomCenter, child: ClipPath(clipper: WaveClipper(), child: Container(height: 95, color: Colors.white))),
          Positioned(top: mobile ? 45 : 35, left: mobile ? 18 : 8, child: Transform.rotate(angle: -.25, child: const HoneyArt(type: HoneyArtType.bee, size: 50))),
          Positioned(bottom: 66, right: mobile ? 18 : 48, child: Transform.rotate(angle: .20, child: const HoneyArt(type: HoneyArtType.bee, size: 45))),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: EdgeInsets.fromLTRB(mobile ? 28 : 55, mobile ? 64 : 35, mobile ? 28 : 55, 80),
                child: mobile
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [_heroText(center: true), const SizedBox(height: 26), const _ProductOrb(size: 190)])
                    : Row(children: [Expanded(child: _heroText()), const SizedBox(width: 55), const _ProductOrb(size: 275)]),
              ),
            ),
          ),
        ]),
      );

  Widget _heroText({bool center = false}) => Column(crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Pure Honey,\nStraight from the Hive', textAlign: center ? TextAlign.center : TextAlign.left, style: TextStyle(color: Colors.white, fontSize: center ? 33 : 47, height: 1.05, fontWeight: FontWeight.w900)),
        const SizedBox(height: 15),
        Text('Blockchain-verified. KVIC-certified.\nFarm to jar traceability.', textAlign: center ? TextAlign.center : TextAlign.left, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 16, height: 1.45)),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: onVerify, icon: const Icon(Icons.verified_outlined, size: 19), label: const Text('Verify Your Honey'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 2), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15), shape: const StadiumBorder(), textStyle: const TextStyle(fontWeight: FontWeight.w900))),
      ]);
}

class _ProductOrb extends StatelessWidget {
  const _ProductOrb({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFFFFE6A7), Color(0xFFE59000)]), border: Border.all(color: Colors.white.withValues(alpha: .65), width: 7), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 12))]),
        child: Stack(alignment: Alignment.center, children: [
          HoneyArt(type: HoneyArtType.jar, size: size * .68),
          Positioned(bottom: size * .14, child: Text('KVIC PURE', style: TextStyle(color: HoneyColors.brown, fontWeight: FontWeight.w900, fontSize: size * .055, letterSpacing: 1))),
        ]),
      );
}

class _TelemetrySection extends StatelessWidget {
  const _TelemetrySection();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: HoneyColors.offWhite,
        padding: const EdgeInsets.fromLTRB(24, 51, 24, 56),
        child: Column(children: [
          Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 30, decoration: BoxDecoration(color: HoneyColors.gold, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 11), const Text('Live Hive Telemetry', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 27),
          const Wrap(alignment: WrapAlignment.center, spacing: 13, runSpacing: 14, children: [
            StatTile(icon: Icons.thermostat_rounded, value: '34.8 °C', label: 'Internal Temp'),
            StatTile(icon: Icons.water_drop_outlined, value: '62%', label: 'Humidity'),
            StatTile(icon: Icons.graphic_eq_rounded, value: '210 Hz', label: 'Bee Buzzing'),
            StatTile(icon: Icons.scale_outlined, value: '42.5 kg', label: 'Hive Weight'),
            StatTile(icon: Icons.favorite_outline_rounded, value: '98%', label: 'Hive Health'),
          ]),
        ]),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: HoneyColors.brown,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const HoneyArt(type: HoneyArtType.bee, size: 28, color: HoneyColors.gold), const SizedBox(width: 7), Text('Honey Chain', style: HoneyTheme.logo.copyWith(color: HoneyColors.gold, fontSize: 25))]),
          const SizedBox(height: 16),
          Text('Dashboard   |   Batch Tracker   |   Verify Honey   |   Profile', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 13)),
          const SizedBox(height: 23),
          Text('Built for KVIC Honey Mission — Smart India Hackathon 2026', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 12)),
        ]),
      );
}

class _FlightPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HoneyColors.gold.withValues(alpha: .5)..style = PaintingStyle.stroke..strokeWidth = 2;
    final path = Path()..moveTo(size.width * .22, size.height * .50)..cubicTo(size.width * .36, size.height * .25, size.width * .39, size.height * .76, size.width * .51, size.height * .48)..cubicTo(size.width * .65, size.height * .25, size.width * .69, size.height * .75, size.width * .82, size.height * .48);
    for (var metric = 0.0; metric < path.computeMetrics().first.length; metric += 10) {
      final extract = path.computeMetrics().first.extractPath(metric, metric + 4);
      canvas.drawPath(extract, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/honey_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final List<_HexData> _hexes;
  _HexData? _hovered;
  final _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _generateHexes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = context.size;
      if (size != null) {
        // Child is 1600x1600. Center is 800,800
        final offsetX = 800.0 - size.width / 2;
        final offsetY = 800.0 - size.height / 2;
        _transformCtrl.value = Matrix4.identity()
          // ignore: deprecated_member_use
          ..translate(-offsetX, -offsetY);
      }
    });
  }

  void _generateHexes() {
    _hexes = [];
    final random = math.Random(42);
    const gridRadius = 26.0; // Distance between centers

    for (int q = -25; q <= 25; q++) {
      int r1 = math.max(-25, -q - 25);
      int r2 = math.min(25, -q + 25);
      for (int r = r1; r <= r2; r++) {
        final x = gridRadius * 3 / 2 * q;
        final y = gridRadius * math.sqrt(3) * (r + q / 2);

        // Calculate distance from center to form a circular cluster
        final dist = math.sqrt(x * x + y * y);
        
        // Hard boundary
        if (dist > 500) continue;
        
        // Organic dissolving edges
        if (dist > 350 && random.nextDouble() > 0.6) continue;
        if (dist > 450 && random.nextDouble() > 0.3) continue;
        
        // Random missing hexes inside
        if (random.nextDouble() > 0.95) continue;

        // Make ~8% of batches "active/live"
        final isActive = random.nextDouble() > 0.92;

        _hexes.add(_HexData(
          cx: x,
          cy: y,
          isActive: isActive,
          id: 'HC-${2020 + random.nextInt(6)}-${random.nextInt(9000) + 1000}',
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Global Honeycomb', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 8),
          Text(
            '${_hexes.length} active batches across the decentralized network.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                border: Border.all(color: AppColors.border),
                borderRadius: AppConstants.cardRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Dot Grid Background
                  CustomPaint(
                    painter: _DotGridPainter(),
                    child: const SizedBox.expand(),
                  ),
                  InteractiveViewer(
                    transformationController: _transformCtrl,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(800),
                    minScale: 0.2,
                    maxScale: 3.0,
                    child: MouseRegion(
                      onHover: (e) {
                        // The custom paint size is fixed at 1600x1600
                        const centerX = 800.0;
                        const centerY = 800.0;
                        
                        final localX = e.localPosition.dx - centerX;
                        final localY = e.localPosition.dy - centerY;

                        _HexData? found;
                        for (final h in _hexes) {
                          if (math.sqrt(math.pow(h.cx - localX, 2) + math.pow(h.cy - localY, 2)) < 22) {
                            found = h;
                            break;
                          }
                        }
                        if (found != _hovered) setState(() => _hovered = found);
                      },
                      child: CustomPaint(
                        painter: _HoneycombPainter(hexes: _hexes, hovered: _hovered),
                        size: const Size(1600, 1600),
                      ),
                    ),
                  ),
                  
                  // Hover Card
                  if (_hovered != null)
                    Positioned(
                      bottom: 24,
                      left: 24,
                      child: _HoverCard(data: _hovered!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverCard extends StatelessWidget {
  const _HoverCard({required this.data});
  final _HexData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.borderHi),
        borderRadius: AppConstants.smallRadius,
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.id, style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STATUS', style: AppTextStyles.label),
              Text(
                data.isActive ? 'LIVE SYNC' : 'ARCHIVED',
                style: AppTextStyles.bodySmall.copyWith(
                  color: data.isActive ? AppColors.green : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HexData {
  _HexData({required this.cx, required this.cy, required this.isActive, required this.id});
  final double cx, cy;
  final bool isActive;
  final String id;
}

class _HoneycombPainter extends CustomPainter {
  _HoneycombPainter({required this.hexes, this.hovered});
  final List<_HexData> hexes;
  final _HexData? hovered;

  @override
  void paint(Canvas canvas, Size size) {
    // Center the entire cluster perfectly in the container
    canvas.translate(size.width / 2, size.height / 2);

    final path = Path();
    const r = 22.0; // The drawn radius (smaller than gridRadius 26.0 to create a 4px exact gap!)

    for (final h in hexes) {
      final isHovered = h == hovered;

      final fill = isHovered
          ? AppColors.textPrimary
          : (h.isActive ? AppColors.green.withValues(alpha: 0.1) : const Color(0xFF141414));

      final stroke = isHovered
          ? AppColors.textPrimary
          : (h.isActive ? AppColors.green : const Color(0xFF222222));

      final paint = Paint()
        ..color = fill
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 2 : 1;

      path.reset();
      for (int i = 0; i < 6; i++) {
        final angle = math.pi / 3 * i;
        final px = h.cx + r * math.cos(angle);
        final py = h.cy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_HoneycombPainter old) => old.hovered != hovered;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        if (y > size.height) break;
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

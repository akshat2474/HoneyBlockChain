import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Interactive Hexagonal Distortion Mesh (Aceternity Dot Distortion -> Hex)
// ─────────────────────────────────────────────────────────────────────────────

class HexDistortionCanvas extends StatefulWidget {
  const HexDistortionCanvas({
    super.key,
    this.pointerNotifier,
    this.cellSize = 42.0,
    this.distortionRadius = 180.0,
    this.distortionStrength = 48.0,
  });

  final ValueNotifier<Offset?>? pointerNotifier;
  final double cellSize;
  final double distortionRadius;
  final double distortionStrength;

  @override
  State<HexDistortionCanvas> createState() => _HexDistortionCanvasState();
}

class _HexDistortionCanvasState extends State<HexDistortionCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;
  Offset? _internalPointer;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    widget.pointerNotifier?.addListener(_onExternalPointerChanged);
  }

  @override
  void didUpdateWidget(covariant HexDistortionCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pointerNotifier != widget.pointerNotifier) {
      oldWidget.pointerNotifier?.removeListener(_onExternalPointerChanged);
      widget.pointerNotifier?.addListener(_onExternalPointerChanged);
    }
  }

  void _onExternalPointerChanged() {
    if (mounted) {
      setState(() {
        _internalPointer = widget.pointerNotifier?.value;
      });
    }
  }

  @override
  void dispose() {
    widget.pointerNotifier?.removeListener(_onExternalPointerChanged);
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return CustomPaint(
            painter: _HexDistortionPainter(
              progress: _ambientController.value,
              pointer: _internalPointer,
              cellSize: widget.cellSize,
              radius: widget.distortionRadius,
              strength: widget.distortionStrength,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _HexDistortionPainter extends CustomPainter {
  _HexDistortionPainter({
    required this.progress,
    required this.pointer,
    required this.cellSize,
    required this.radius,
    required this.strength,
  });

  final double progress;
  final Offset? pointer;
  final double cellSize;
  final double radius;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final hexWidth = cellSize * 2;
    final hexHeight = cellSize * sqrt(3);
    final cols = (size.width / (hexWidth * 0.75)).ceil() + 2;
    final rows = (size.height / hexHeight).ceil() + 2;

    // Base visible honeycomb grid lines
    final baseLinePaint = Paint()
      ..color = const Color(0xFF333333).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final ambientPhase = progress * 2 * pi;

    for (var r = -1; r < rows; r++) {
      for (var c = -1; c < cols; c++) {
        final originX = c * hexWidth * 0.75;
        final originY = r * hexHeight + (c.isOdd ? hexHeight / 2 : 0);
        final center = Offset(originX, originY);

        // Distance to pointer
        double distToPointer = 9999.0;
        if (pointer != null) {
          distToPointer = (center - pointer!).distance;
        }

        final isNearPointer = distToPointer < radius;

        // Calculate displaced center with elastic spring repulsion & ambient drift
        Offset displacedCenter = center;

        // Subtle ambient breathing drift
        final driftX = sin(ambientPhase + (r * 0.5) + (c * 0.4)) * 2.5;
        final driftY = cos(ambientPhase + (r * 0.4) + (c * 0.5)) * 2.5;
        displacedCenter += Offset(driftX, driftY);

        // Interactive elastic repulsion from cursor
        if (isNearPointer && pointer != null) {
          final factor = 1.0 - (distToPointer / radius);
          // Elastic spring curve: dramatic push outwards
          final push = sin(factor * pi / 2) * strength;
          final dir = (center - pointer!);
          final dist = dir.distance;
          final normDir = dist > 0.001
              ? Offset(dir.dx / dist, dir.dy / dist)
              : const Offset(1, 0);

          displacedCenter += normDir * push;
        }

        // Draw 6-sided hexagon
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = (pi / 3) * i - pi / 6;
          final vx = displacedCenter.dx + cellSize * cos(angle);
          final vy = displacedCenter.dy + cellSize * sin(angle);

          if (i == 0) {
            path.moveTo(vx, vy);
          } else {
            path.lineTo(vx, vy);
          }
        }
        path.close();

        // Illuminate and glow near the cursor
        if (isNearPointer) {
          final proximity = 1.0 - (distToPointer / radius);

          // Glowing amber hex cell
          final glowPaint = Paint()
            ..color = AppColors.amber.withValues(alpha: 0.25 + (proximity * 0.65))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2 + (proximity * 1.6);
          canvas.drawPath(path, glowPaint);

          // Hex center node dot
          canvas.drawCircle(
            displacedCenter,
            2.0 + (proximity * 3.0),
            Paint()
              ..color = AppColors.amber.withValues(alpha: 0.4 + (proximity * 0.6)),
          );
        } else {
          // Standard visible wireframe
          canvas.drawPath(path, baseLinePaint);

          // Occasional subtle node dot
          if ((r + c) % 2 == 0) {
            canvas.drawCircle(
              displacedCenter,
              1.2,
              Paint()..color = const Color(0xFF444444).withValues(alpha: 0.4),
            );
          }
        }
      }
    }

    // Glowing amber spotlight aura following the pointer
    if (pointer != null) {
      final spotlightPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (pointer!.dx / size.width) * 2 - 1,
            (pointer!.dy / size.height) * 2 - 1,
          ),
          radius: (radius * 1.3) / max(size.width, size.height),
          colors: [
            AppColors.amber.withValues(alpha: 0.18),
            AppColors.amber.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, spotlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HexDistortionPainter old) => true;
}

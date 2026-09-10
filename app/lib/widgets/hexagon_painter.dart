import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HexagonClipper — Clips any widget into a regular hexagon
// ─────────────────────────────────────────────────────────────────────────────

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _hexPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _hexPath(Size size) {
  final w = size.width;
  final h = size.height;
  final cx = w / 2;
  final cy = h / 2;
  final r = min(w, h) / 2;

  final path = Path();
  for (var i = 0; i < 6; i++) {
    // Flat-top hexagon: starts at 0° (right edge)
    final angle = (pi / 3) * i - pi / 6;
    final x = cx + r * cos(angle);
    final y = cy + r * sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

// ─────────────────────────────────────────────────────────────────────────────
// HexagonBorder — Draws a glowing hex border around a widget
// ─────────────────────────────────────────────────────────────────────────────

class HexagonBorder extends CustomPainter {
  HexagonBorder({
    this.borderColor = AppColors.border,
    this.glowColor,
    this.strokeWidth = 1.0,
  });

  final Color borderColor;
  final Color? glowColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size);

    // Glow layer
    if (glowColor != null) {
      final glowPaint = Paint()
        ..color = glowColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
      canvas.drawPath(path, glowPaint);
    }

    // Border line
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant HexagonBorder old) =>
      old.borderColor != borderColor ||
      old.glowColor != glowColor ||
      old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────────────────────
// HexGridBackground — Faint tessellated hex wireframe fading to black
// ─────────────────────────────────────────────────────────────────────────────

class HexGridBackground extends CustomPainter {
  HexGridBackground({this.cellSize = 40, this.opacity = 0.08});

  final double cellSize;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderLight.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final hexWidth = cellSize * 2;
    final hexHeight = cellSize * sqrt(3);
    final cols = (size.width / (hexWidth * 0.75)).ceil() + 2;
    final rows = (size.height / hexHeight).ceil() + 2;

    for (var row = -1; row < rows; row++) {
      for (var col = -1; col < cols; col++) {
        final offsetX = col * hexWidth * 0.75;
        final offsetY = row * hexHeight + (col.isOdd ? hexHeight / 2 : 0);
        _drawHex(canvas, Offset(offsetX, offsetY), cellSize, paint);
      }
    }

    // Fade to black at edges using radial gradient overlay
    final rect = Offset.zero & size;
    final fadePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.transparent,
          AppColors.canvas.withValues(alpha: 0.6),
          AppColors.canvas,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, fadePaint);
  }

  void _drawHex(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HexGridBackground old) =>
      old.cellSize != cellSize || old.opacity != opacity;
}

// ─────────────────────────────────────────────────────────────────────────────
// HexagonWidget — Convenience wrapper widget with hex clip + border
// ─────────────────────────────────────────────────────────────────────────────

class HexagonWidget extends StatelessWidget {
  const HexagonWidget({
    super.key,
    required this.size,
    required this.child,
    this.borderColor = AppColors.border,
    this.glowColor,
    this.fillColor,
  });

  final double size;
  final Widget child;
  final Color borderColor;
  final Color? glowColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HexagonBorder(
          borderColor: borderColor,
          glowColor: glowColor,
          strokeWidth: 1.2,
        ),
        child: ClipPath(
          clipper: HexagonClipper(),
          child: Container(
            color: fillColor ?? AppColors.card,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

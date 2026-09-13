import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';

class IndiaHiveMap extends StatefulWidget {
  const IndiaHiveMap({
    super.key,
    required this.pins,
    this.onPinTap,
  });
  final List<HivePin> pins;
  final ValueChanged<HivePin>? onPinTap;

  @override
  State<IndiaHiveMap> createState() => _IndiaHiveMapState();
}

class _IndiaHiveMapState extends State<IndiaHiveMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  HivePin? _hovered;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return CustomPaint(
          painter: _IndiaPainter(
            pins: widget.pins,
            pulseValue: _pulse.value,
            hovered: _hovered,
          ),
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details.localPosition, context),
            child: MouseRegion(
              onHover: (e) => _handleHover(e.localPosition, context),
              onExit: (_) => setState(() => _hovered = null),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset pos, BuildContext ctx) {
    final size = context.size;
    if (size == null) return;
    final pin = _pinAt(pos, size);
    if (pin != null) widget.onPinTap?.call(pin);
  }

  void _handleHover(Offset pos, BuildContext ctx) {
    final size = context.size;
    if (size == null) return;
    final pin = _pinAt(pos, size);
    if (pin != _hovered) setState(() => _hovered = pin);
  }

  HivePin? _pinAt(Offset pos, Size size) {
    for (final pin in widget.pins) {
      final p = _IndiaPainter.geoToCanvas(pin.lat, pin.lng, size);
      if ((p - pos).distance < 12) return pin;
    }
    return null;
  }
}

class _IndiaPainter extends CustomPainter {
  const _IndiaPainter({
    required this.pins,
    required this.pulseValue,
    this.hovered,
  });

  final List<HivePin> pins;
  final double pulseValue;
  final HivePin? hovered;

  static const double _latMin = 6.0;
  static const double _latMax = 37.0;
  static const double _lngMin = 68.0;
  static const double _lngMax = 97.5;

  static Offset geoToCanvas(double lat, double lng, Size size) {
    final x = (lng - _lngMin) / (_lngMax - _lngMin) * size.width;
    final y = (1 - (lat - _latMin) / (_latMax - _latMin)) * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBorder(canvas, size);
    _drawPins(canvas, size);
  }

  void _drawBorder(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);
    _drawIndiaOutline(canvas, size);
  }

  void _drawIndiaOutline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderHi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final pts = <List<double>>[
      [37.0, 74.9], [36.5, 75.8], [34.5, 77.0], [32.7, 78.5],
      [31.0, 77.0], [30.7, 76.8], [29.5, 73.5], [28.6, 70.5],
      [27.2, 68.2], [23.5, 68.0], [22.0, 68.8], [20.5, 66.5],
      [20.5, 68.0], [22.0, 70.3], [20.8, 71.5], [20.0, 73.0],
      [17.5, 73.5], [15.0, 74.0], [12.0, 74.8], [8.5,  77.5],
      [8.0,  78.0], [9.0,  79.5], [10.5, 80.0], [13.5, 80.3],
      [15.5, 80.2], [17.5, 82.3], [19.0, 85.0], [20.5, 86.7],
      [21.5, 87.5], [22.5, 88.0], [23.0, 88.5], [24.0, 88.1],
      [24.5, 88.8], [25.5, 89.0], [26.0, 89.9], [27.0, 89.6],
      [27.5, 91.5], [26.5, 92.5], [26.5, 93.5], [27.5, 95.0],
      [28.0, 96.5], [27.0, 97.5], [25.0, 97.0], [24.5, 95.0],
      [23.0, 94.0], [22.0, 93.5], [21.5, 92.5], [23.0, 91.5],
      [22.5, 90.5], [21.5, 89.0], [22.5, 88.5], [22.5, 87.0],
      [20.0, 86.5], [18.0, 84.0], [16.0, 82.5], [14.5, 80.5],
      [12.0, 80.0], [9.0,  78.5], [8.0,  77.5], [8.5,  76.5],
      [10.0, 76.5], [11.5, 75.8], [14.0, 75.0], [16.5, 74.2],
      [19.0, 73.0], [22.0, 72.5], [23.5, 68.5], [24.0, 68.0],
      [26.0, 69.0], [28.0, 70.0], [29.0, 71.5], [31.0, 73.5],
      [32.5, 74.5], [34.0, 74.0], [35.5, 74.5], [37.0, 74.9],
    ];

    if (pts.isEmpty) return;
    final path = Path();
    final first = geoToCanvas(pts[0][0], pts[0][1], size);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p = geoToCanvas(pts[i][0], pts[i][1], size);
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPins(Canvas canvas, Size size) {
    for (final pin in pins) {
      final offset = geoToCanvas(pin.lat, pin.lng, size);
      final isHov = hovered == pin;

      if (pin.isRecent) {
        final pulseRadius = 6.0 + pulseValue * 8.0;
        final pulsePaint = Paint()
          ..color = AppColors.green.withValues(alpha: (1 - pulseValue) * 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, pulseRadius, pulsePaint);
      }

      final dotPaint = Paint()
        ..color = isHov
            ? AppColors.textPrimary
            : pin.isRecent
                ? AppColors.green
                : AppColors.textMuted
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, isHov ? 6 : 4, dotPaint);

      if (isHov) {
        final tp = TextPainter(
          text: TextSpan(
            text: pin.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontFamily: 'Roboto Mono',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final bgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx + 10, offset.dy - 12,
              tp.width + 12, tp.height + 8),
          const Radius.circular(4),
        );
        canvas.drawRRect(bgRect, Paint()..color = AppColors.card);
        canvas.drawRRect(bgRect, Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
        tp.paint(canvas, Offset(offset.dx + 16, offset.dy - 8));
      }
    }
  }

  @override
  bool shouldRepaint(_IndiaPainter old) =>
      old.pulseValue != pulseValue || old.hovered != hovered;
}

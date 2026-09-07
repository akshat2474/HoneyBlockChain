import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

enum HoneyArtType { bee, hive, jar, dipper }

class HoneyArt extends StatelessWidget {
  const HoneyArt({super.key, required this.type, this.size = 72, this.color});

  final HoneyArtType type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _HoneyArtPainter(type, color),
      );
}

class _HoneyArtPainter extends CustomPainter {
  _HoneyArtPainter(this.type, this.color);
  final HoneyArtType type;
  final Color? color;

  Paint fill(Color value) => Paint()..color = value;
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = color ?? HoneyColors.brown;
    switch (type) {
      case HoneyArtType.bee:
        stroke.color = dark;
        canvas.drawOval(Rect.fromLTWH(w * .14, h * .20, w * .34, h * .27), fill(Colors.white.withValues(alpha: .78)));
        canvas.drawOval(Rect.fromLTWH(w * .52, h * .12, w * .30, h * .30), fill(Colors.white.withValues(alpha: .78)));
        canvas.drawOval(Rect.fromLTWH(w * .23, h * .35, w * .53, h * .35), fill(HoneyColors.gold));
        canvas.drawOval(Rect.fromLTWH(w * .23, h * .35, w * .53, h * .35), stroke);
        for (final x in [.39, .52, .65]) {
          canvas.drawLine(Offset(w * x, h * .37), Offset(w * x, h * .68), stroke);
        }
        canvas.drawCircle(Offset(w * .80, h * .52), w * .12, fill(dark));
        canvas.drawCircle(Offset(w * .84, h * .49), w * .018, fill(Colors.white));
        canvas.drawArc(Rect.fromLTWH(w * .66, h * .13, w * .26, h * .25), 3.7, 1.7, false, stroke);
      case HoneyArtType.hive:
        final hive = Path()
          ..moveTo(w * .20, h * .85)
          ..lineTo(w * .20, h * .42)
          ..quadraticBezierTo(w * .50, h * .02, w * .80, h * .42)
          ..lineTo(w * .80, h * .85)
          ..close();
        canvas.drawPath(hive, fill(HoneyColors.gold));
        stroke.color = dark;
        canvas.drawPath(hive, stroke);
        for (final y in [.47, .60, .73]) {
          canvas.drawLine(Offset(w * .22, h * y), Offset(w * .78, h * y), stroke);
        }
        canvas.drawOval(Rect.fromLTWH(w * .38, h * .63, w * .24, h * .17), fill(dark));
      case HoneyArtType.jar:
        final jar = RRect.fromRectAndRadius(Rect.fromLTWH(w * .23, h * .28, w * .54, h * .57), Radius.circular(w * .11));
        canvas.drawRRect(jar, fill(HoneyColors.gold));
        stroke.color = dark;
        canvas.drawRRect(jar, stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .30, h * .16, w * .40, h * .15), const Radius.circular(5)), fill(dark));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .32, h * .47, w * .36, h * .20), const Radius.circular(7)), fill(Colors.white));
        canvas.drawCircle(Offset(w * .50, h * .57), w * .07, fill(HoneyColors.goldDark));
      case HoneyArtType.dipper:
        canvas.save();
        canvas.rotate(-.55);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .38, h * .12, w * .15, h * .68), const Radius.circular(20)), fill(dark));
        canvas.drawOval(Rect.fromLTWH(w * .22, h * .55, w * .46, h * .27), fill(HoneyColors.gold));
        stroke.color = dark;
        for (final y in [.60, .67, .74]) {
          canvas.drawLine(Offset(w * .24, h * y), Offset(w * .66, h * y), stroke);
        }
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HoneyArtPainter oldDelegate) => oldDelegate.type != type || oldDelegate.color != color;
}

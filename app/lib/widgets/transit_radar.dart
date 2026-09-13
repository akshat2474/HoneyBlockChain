import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

class TransitRadar extends StatefulWidget {
  const TransitRadar({super.key});
  @override
  State<TransitRadar> createState() => _TransitRadarState();
}

class _TransitRadarState extends State<TransitRadar> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: AppConstants.cardRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => CustomPaint(
              painter: _RadarPainter(progress: _anim.value),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 24, left: 24,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('LIVE TRANSIT RADAR', style: AppTextStyles.label.copyWith(color: AppColors.green)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progress});
  final double progress;

  static const double _latMin = 6.0;
  static const double _latMax = 37.0;
  static const double _lngMin = 68.0;
  static const double _lngMax = 97.5;

  static Offset geoToCanvas(double lat, double lng, Size size) {
    // adding padding
    final padding = size.width * 0.1;
    final w = size.width - padding*2;
    final h = size.height - padding*2;
    final x = padding + (lng - _lngMin) / (_lngMax - _lngMin) * w;
    final y = padding + (1 - (lat - _latMin) / (_latMax - _latMin)) * h;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawIndia(canvas, size);
    _drawArcs(canvas, size);
  }

  void _drawIndia(Canvas canvas, Size size) {
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

  void _drawArcs(Canvas canvas, Size size) {
    // 1. Bharatpur (Beekeeper)
    final p1 = geoToCanvas(27.1751, 77.50, size);
    // 2. Delhi (Lab)
    final p2 = geoToCanvas(28.6139, 77.2090, size);
    // 3. Mumbai (Consumer)
    final p3 = geoToCanvas(19.0760, 72.8777, size);

    _drawArc(canvas, p1, p2, 0.0, 0.5);
    _drawArc(canvas, p2, p3, 0.5, 1.0);
    
    _drawNode(canvas, p1, 'FARM');
    _drawNode(canvas, p2, 'LAB');
    _drawNode(canvas, p3, 'STORE');
  }
  
  void _drawNode(Canvas canvas, Offset p, String label) {
    canvas.drawCircle(p, 4, Paint()..color = AppColors.textPrimary);
    final tp = TextPainter(
      text: TextSpan(text: label, style: AppTextStyles.mono.copyWith(fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(p.dx + 8, p.dy - 5));
  }

  void _drawArc(Canvas canvas, Offset p1, Offset p2, double startProg, double endProg) {
    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    
    // Calculate control point for a nice arc
    final cx = (p1.dx + p2.dx) / 2 + 50; // curve offset
    final cy = (p1.dy + p2.dy) / 2 - 50;
    
    path.quadraticBezierTo(cx, cy, p2.dx, p2.dy);
    
    // Base dashed line
    final basePaint = Paint()
      ..color = AppColors.borderHi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    _drawDashed(canvas, path, basePaint);
    
    // Animated glowing arc
    // local progress
    double p = 0;
    if (progress >= startProg && progress <= endProg) {
      p = (progress - startProg) / (endProg - startProg);
    } else if (progress > endProg) {
      p = 1.0;
    }
    
    if (p > 0) {
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) return;
      final m = metrics[0];
      final drawPath = m.extractPath(0, m.length * p);
      
      canvas.drawPath(drawPath, Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3)
      );
      
      // leading dot
      if (p < 1.0) {
        final pos = m.getTangentForOffset(m.length * p)?.position;
        if (pos != null) {
          canvas.drawCircle(pos, 4, Paint()..color = AppColors.textPrimary);
          canvas.drawCircle(pos, 8, Paint()..color = AppColors.green.withValues(alpha: 0.5));
        }
      }
    }
  }
  
  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics[0];
    double distance = 0.0;
    final dashPath = Path();
    while (distance < m.length) {
      dashPath.addPath(m.extractPath(distance, distance + 5), Offset.zero);
      distance += 10;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}

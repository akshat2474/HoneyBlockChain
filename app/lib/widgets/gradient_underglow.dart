import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GradientUnderglow — Ambient Breathing Amber/Blue Radial Aura
// ─────────────────────────────────────────────────────────────────────────────

class GradientUnderglow extends StatefulWidget {
  const GradientUnderglow({
    super.key,
    required this.child,
    this.primaryColor = AppColors.amber,
    this.secondaryColor = AppColors.blue,
  });

  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  State<GradientUnderglow> createState() => _GradientUnderglowState();
}

class _GradientUnderglowState extends State<GradientUnderglow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final scale = 1.0 + (_glowController.value * 0.08);
        final opacity = 0.08 + (_glowController.value * 0.08);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient radial aura
            Transform.scale(
              scale: scale,
              child: Container(
                width: 320,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(100),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      widget.primaryColor.withValues(alpha: opacity),
                      widget.secondaryColor.withValues(alpha: opacity * 0.5),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RollingCounterText — Smooth Number Counter Roll-Up (TweenAnimationBuilder)
// ─────────────────────────────────────────────────────────────────────────────

class RollingCounterText extends StatelessWidget {
  const RollingCounterText({
    super.key,
    required this.targetValue,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 1400),
    this.style,
  });

  final double targetValue;
  final String prefix;
  final String suffix;
  final int decimals;
  final Duration duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetValue),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, val, _) {
        final formatted = decimals == 0
            ? val.toInt().toString()
            : val.toStringAsFixed(decimals);
        return Text(
          '$prefix$formatted$suffix',
          style: style ?? AppTextStyles.stat,
        );
      },
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BlurFadeIn — Blur filter + upward slide + opacity entrance animation
// ─────────────────────────────────────────────────────────────────────────────

class BlurFadeIn extends StatefulWidget {
  const BlurFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
    this.blurRadius = 8.0,
    this.slideOffset = const Offset(0, 18),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double blurRadius;
  final Offset slideOffset;

  @override
  State<BlurFadeIn> createState() => _BlurFadeInState();
}

class _BlurFadeInState extends State<BlurFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;
        final currentBlur = (1.0 - progress) * widget.blurRadius;
        final currentSlide = Offset(
          widget.slideOffset.dx * (1.0 - progress),
          widget.slideOffset.dy * (1.0 - progress),
        );

        return Transform.translate(
          offset: currentSlide,
          child: Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: currentBlur > 0.1
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: currentBlur,
                      sigmaY: currentBlur,
                    ),
                    child: widget.child,
                  )
                : widget.child,
          ),
        );
      },
    );
  }
}

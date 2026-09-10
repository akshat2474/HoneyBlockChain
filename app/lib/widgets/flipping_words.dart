import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/honey_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FlippingWords — 3D Vertical Rotating Word Animation (Aceternity Style)
// ─────────────────────────────────────────────────────────────────────────────

class FlippingWords extends StatefulWidget {
  const FlippingWords({
    super.key,
    required this.words,
    this.interval = const Duration(milliseconds: 2600),
    this.textStyle,
  });

  final List<String> words;
  final Duration interval;
  final TextStyle? textStyle;

  @override
  State<FlippingWords> createState() => _FlippingWordsState();
}

class _FlippingWordsState extends State<FlippingWords>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  late final AnimationController _flipController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeOutBack),
    );

    _flipController.forward();

    _timer = Timer.periodic(widget.interval, (_) {
      _flipController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.words.length;
        });
        _flipController.forward();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ??
        GoogleFonts.spaceGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
        );

    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 30),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: _opacityAnimation.value.clamp(0.0, 1.0),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    AppColors.amber,
                    Color(0xFFFFD000),
                  ],
                  stops: [0.0, 0.65, 1.0],
                ).createShader(bounds),
                child: Text(
                  widget.words[_currentIndex],
                  style: style.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

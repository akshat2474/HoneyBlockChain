import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import 'hexagon_painter.dart';
import 'gradient_underglow.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HexStatCard — Hexagon-clipped metric card with counter & hover scale
// ─────────────────────────────────────────────────────────────────────────────

class HexStatCard extends StatefulWidget {
  const HexStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.numericTarget,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.accentColor = AppColors.amber,
    this.size = 150,
  });

  final String label;
  final String value;
  final IconData icon;
  final double? numericTarget;
  final String prefix;
  final String suffix;
  final int decimals;
  final Color accentColor;
  final double size;

  @override
  State<HexStatCard> createState() => _HexStatCardState();
}

class _HexStatCardState extends State<HexStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: HexagonWidget(
          size: widget.size,
          borderColor: _isHovered
              ? widget.accentColor
              : widget.accentColor.withValues(alpha: 0.4),
          glowColor: _isHovered
              ? widget.accentColor.withValues(alpha: 0.35)
              : widget.accentColor.withValues(alpha: 0.15),
          fillColor: AppColors.card,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.accentColor, size: 22),
                const SizedBox(height: 6),
                if (widget.numericTarget != null)
                  RollingCounterText(
                    targetValue: widget.numericTarget!,
                    prefix: widget.prefix,
                    suffix: widget.suffix,
                    decimals: widget.decimals,
                    style: AppTextStyles.stat.copyWith(fontSize: 20),
                  )
                else
                  Text(
                    widget.value,
                    style: AppTextStyles.stat.copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: AppTextStyles.label.copyWith(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

class VercelCard extends StatelessWidget {
  const VercelCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppConstants.cardRadius,
        border: Border.all(color: borderColor ?? AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.size = 6});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool monospace;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(
          value,
          style: monospace
              ? AppTextStyles.mono.copyWith(color: valueColor ?? AppColors.textSecondary)
              : AppTextStyles.bodySmall.copyWith(color: valueColor ?? AppColors.textSecondary),
        ),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(text.toUpperCase(), style: AppTextStyles.label),
    );
  }
}

class TokenBadge extends StatelessWidget {
  const TokenBadge({super.key, this.standard = 'ERC-721', this.tokenId = '#4829'});
  final String standard;
  final String tokenId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: AppConstants.pillRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$standard $tokenId',
        style: AppTextStyles.mono.copyWith(fontSize: 11),
      ),
    );
  }
}

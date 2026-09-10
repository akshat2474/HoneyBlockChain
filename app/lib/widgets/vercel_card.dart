import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VercelCard — Dark surface card, the primary container widget
// ─────────────────────────────────────────────────────────────────────────────

class VercelCard extends StatelessWidget {
  const VercelCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: AppConstants.cardRadius,
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// InfoRow — Label : Value horizontal row
// ─────────────────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.monospace = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: AppTextStyles.label),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: (monospace ? AppTextStyles.mono : AppTextStyles.body)
                .copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionLabel — Uppercase section divider label
// ─────────────────────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(text.toUpperCase(), style: AppTextStyles.label),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusDot — Colored status indicator
// ─────────────────────────────────────────────────────────────────────────────

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TokenBadge — Small inline badge for ERC-721 token info
// ─────────────────────────────────────────────────────────────────────────────

class TokenBadge extends StatelessWidget {
  const TokenBadge({super.key, this.standard = 'ERC-721', this.tokenId = '#4829'});

  final String standard;
  final String tokenId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: AppConstants.smallRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            standard,
            style: AppTextStyles.label.copyWith(
              color: AppColors.amber,
              fontSize: 9,
            ),
          ),
          Text(
            'Token $tokenId',
            style: AppTextStyles.mono.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LabRow — Lab test result row with pass/fail indicator
// ─────────────────────────────────────────────────────────────────────────────

class LabRow extends StatelessWidget {
  const LabRow({
    super.key,
    required this.metric,
    required this.result,
    required this.detail,
    required this.passed,
  });

  final String metric;
  final String result;
  final String detail;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric, style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(detail, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          result,
          textAlign: TextAlign.right,
          style: AppTextStyles.mono.copyWith(
            color: passed ? AppColors.green : AppColors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PrimaryButton — Solid white / dark text CTA (Vercel style)
// ─────────────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: expand ? double.infinity : null,
      height: 44,
      child: icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: _style,
            )
          : FilledButton(
              onPressed: onPressed,
              style: _style,
              child: Text(label),
            ),
    );
    return button;
  }

  static final _style = FilledButton.styleFrom(
    backgroundColor: AppColors.textPrimary,
    foregroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: AppConstants.smallRadius,
    ),
    textStyle: AppTextStyles.cardHeading.copyWith(
      color: AppColors.canvas,
      fontSize: 13,
    ),
    elevation: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SecondaryButton — Dark outlined button
// ─────────────────────────────────────────────────────────────────────────────

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: expand ? double.infinity : null,
      height: 44,
      child: icon != null
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: Text(label),
              style: _style,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: _style,
              child: Text(label),
            ),
    );
    return button;
  }

  static final _style = OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    side: AppConstants.borderSide,
    shape: const RoundedRectangleBorder(
      borderRadius: AppConstants.smallRadius,
    ),
    textStyle: AppTextStyles.body.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 13,
    ),
    elevation: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AmberButton — Honey gold accent button for key actions
// ─────────────────────────────────────────────────────────────────────────────

class AmberButton extends StatelessWidget {
  const AmberButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: expand ? double.infinity : null,
      height: 44,
      child: icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: _style,
            )
          : FilledButton(
              onPressed: onPressed,
              style: _style,
              child: Text(label),
            ),
    );
    return button;
  }

  static final _style = FilledButton.styleFrom(
    backgroundColor: AppColors.amber,
    foregroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: AppConstants.smallRadius,
    ),
    textStyle: AppTextStyles.cardHeading.copyWith(
      color: AppColors.canvas,
      fontSize: 13,
    ),
    elevation: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PillBadge — Rounded pill badge with optional pulsing dot
// ─────────────────────────────────────────────────────────────────────────────

class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.text,
    this.dotColor,
    this.textColor = AppColors.textSecondary,
  });

  final String text;
  final Color? dotColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: AppConstants.pillRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor!.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: AppTextStyles.badge.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

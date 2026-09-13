import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.canvas,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppConstants.smallRadius),
          textStyle: AppTextStyles.cardHeading.copyWith(color: AppColors.canvas, fontSize: 13),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: AppConstants.borderSideHi,
          shape: const RoundedRectangleBorder(borderRadius: AppConstants.smallRadius),
          textStyle: AppTextStyles.cardHeading.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}

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
      children: [
        Expanded(
          flex: 2,
          child: Text(metric, style: AppTextStyles.label),
        ),
        Expanded(
          flex: 1,
          child: Text(
            result,
            style: AppTextStyles.mono.copyWith(
                color: passed ? AppColors.green : AppColors.red),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(detail,
              style: AppTextStyles.bodySmall, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

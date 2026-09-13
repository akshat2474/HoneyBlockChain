import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

class HexNode extends StatelessWidget {
  const HexNode({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.isLast,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.cardRadius,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.textPrimary : AppColors.inset,
                    borderRadius: AppConstants.smallRadius,
                    border: Border.all(
                      color: isCompleted ? AppColors.textPrimary : AppColors.borderHi,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : icon,
                    size: 12,
                    color: isCompleted ? AppColors.canvas : AppColors.textMuted,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1, height: 52,
                    color: AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppConstants.cardRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.cardHeading),
                          const SizedBox(height: 2),
                          Text(subtitle, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.inset,
                          borderRadius: AppConstants.pillRadius,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 5, height: 5,
                                decoration: const BoxDecoration(
                                    color: AppColors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('DONE',
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.green, fontSize: 9)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HexNodeDetailSheet extends StatelessWidget {
  const HexNodeDetailSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.details,
    this.transactionHash,
  });

  final String title;
  final IconData icon;
  final Map<String, String> details;
  final String? transactionHash;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32, height: 3,
                decoration: BoxDecoration(
                    color: AppColors.borderHi,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.sectionHeading),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            ...details.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(entry.key, style: AppTextStyles.label),
                      ),
                      Expanded(
                        child: Text(entry.value,
                            style: AppTextStyles.mono,
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                )),
            if (transactionHash != null) ...[
              const Divider(height: 20, color: AppColors.border),
              Text('TX HASH', style: AppTextStyles.label),
              const SizedBox(height: 6),
              SelectableText(
                transactionHash!,
                style: AppTextStyles.mono.copyWith(color: AppColors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

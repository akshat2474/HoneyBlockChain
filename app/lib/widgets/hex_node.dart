import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HexNode — Supply chain hexagonal milestone node
// ─────────────────────────────────────────────────────────────────────────────

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
    final accentColor = isCompleted ? AppColors.amber : AppColors.border;
    final iconColor = isCompleted ? AppColors.amber : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.cardRadius,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node column with connector line
          Column(
            children: [
              // Hex-styled node indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.amber.withValues(alpha: 0.12)
                      : AppColors.inset,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 1.5),
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              // Connector line
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accentColor,
                        accentColor.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppConstants.cardRadius,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.amber.withValues(alpha: 0.25)
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.cardHeading,
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.greenGlow,
                            borderRadius: AppConstants.pillRadius,
                          ),
                          child: Text(
                            'DONE',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.green,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HexNodeDetailSheet — Bottom sheet showing node details
// ─────────────────────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Title
            Row(
              children: [
                Icon(icon, color: AppColors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: AppTextStyles.sectionHeading),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            // Detail rows
            ...details.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(entry.key, style: AppTextStyles.label),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTextStyles.mono.copyWith(fontSize: 12),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )),
            // Transaction hash
            if (transactionHash != null) ...[
              const Divider(height: 20, color: AppColors.border),
              Text('TRANSACTION HASH', style: AppTextStyles.label),
              const SizedBox(height: 6),
              SelectableText(
                transactionHash!,
                style: AppTextStyles.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

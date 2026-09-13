import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../widgets/transit_radar.dart';

class TraceabilityScreen extends StatelessWidget {
  const TraceabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        
        final listContent = ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Traceability Provenance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('HC-2026-0847', style: AppTextStyles.mono),
            SizedBox(height: 32),
            _TimelineNode(
              title: 'Retail / Consumer',
              subtitle: 'Scanned via NFC',
              timestamp: 'Pending...',
              isLast: false,
              isCompleted: false,
              child: _SummaryCard(),
            ),
            _TimelineNode(
              title: 'Quality Lab Verification',
              subtitle: 'Delhi Central Lab',
              timestamp: '2026-09-08 11:20:00 UTC',
              isLast: false,
              isCompleted: true,
            ),
            _TimelineNode(
              title: 'Beekeeper Harvest',
              subtitle: 'Bharatpur, Rajasthan',
              timestamp: '2026-09-07 08:14:32 UTC',
              isLast: true,
              isCompleted: true,
            ),
          ],
        );

        if (!isWide) {
          return listContent;
        }

        return Row(
          children: [
            Expanded(flex: 40, child: listContent),
            Container(width: 1, color: AppColors.border),
            const Expanded(flex: 60, child: Padding(
              padding: EdgeInsets.all(24),
              child: TransitRadar(),
            )),
          ],
        );
      }
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isLast,
    required this.isCompleted,
    this.child,
  });

  final String title;
  final String subtitle;
  final String timestamp;
  final bool isLast;
  final bool isCompleted;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.green : AppColors.card,
                    border: Border.all(color: isCompleted ? AppColors.green : AppColors.borderHi, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.green.withValues(alpha: 0.5) : AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text(timestamp, style: AppTextStyles.mono.copyWith(fontSize: 10, color: AppColors.textMuted)),
                  if (child != null) ...[
                    SizedBox(height: 16),
                    child!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: AppConstants.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STATUS', style: AppTextStyles.label),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('VERIFIED', style: AppTextStyles.mono.copyWith(color: AppColors.green, fontSize: 10)),
              )
            ],
          ),
          SizedBox(height: 12),
          const Divider(color: AppColors.borderHi),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PURITY', style: AppTextStyles.label),
              Text('99.8%', style: AppTextStyles.mono),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ORIGIN', style: AppTextStyles.label),
              Text('Bharatpur', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

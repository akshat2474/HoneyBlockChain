import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/hexagon_painter.dart';
import '../widgets/hex_node.dart';
import '../widgets/vercel_card.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN 2: Supply Chain Traceability Flow
// ═════════════════════════════════════════════════════════════════════════════

class TraceabilityScreen extends StatelessWidget {
  const TraceabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Stack(
          children: [
            // Faint hex grid background
            Positioned.fill(
              child: CustomPaint(
                painter: HexGridBackground(
                  cellSize: isWide ? 50 : 35,
                  opacity: 0.05,
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: Padding(
                    padding: AppConstants.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Supply Chain Traceability',
                          style: AppTextStyles.pageTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track honey from hive to shelf — every step cryptographically sealed.',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 8),
                        // Active batch indicator
                        VercelCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const StatusDot(color: AppColors.green),
                              const SizedBox(width: 10),
                              Text(
                                'Viewing: ',
                                style: AppTextStyles.bodySmall,
                              ),
                              Text(
                                'HC-2026-0847',
                                style: AppTextStyles.mono.copyWith(
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '5/5 COMPLETE',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.green,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Traceability nodes
                        ...List.generate(
                          MockData.traceabilityNodes.length,
                          (index) {
                            final node = MockData.traceabilityNodes[index];
                            return HexNode(
                              title: node.title,
                              subtitle: node.subtitle,
                              icon: node.icon,
                              isCompleted: node.isCompleted,
                              isLast:
                                  index == MockData.traceabilityNodes.length - 1,
                              onTap: () => _showNodeDetails(context, node),
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        // Summary card
                        const _TraceabilitySummary(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNodeDetails(BuildContext context, TraceabilityNode node) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => HexNodeDetailSheet(
        title: node.title,
        icon: node.icon,
        details: node.details,
        transactionHash: node.transactionHash,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Traceability Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _TraceabilitySummary extends StatelessWidget {
  const _TraceabilitySummary();

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      borderColor: AppColors.amber.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded,
                  color: AppColors.amber, size: 20),
              const SizedBox(width: 8),
              Text('FULL PROVENANCE VERIFIED',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.amber,
                    letterSpacing: 1,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          const InfoRow(label: 'BATCH', value: 'HC-2026-0847', monospace: true),
          const SizedBox(height: 8),
          const InfoRow(
              label: 'BEEKEEPER', value: 'Ramesh Kumar'),
          const SizedBox(height: 8),
          const InfoRow(
              label: 'ORIGIN', value: 'Bharatpur, Rajasthan'),
          const SizedBox(height: 8),
          const InfoRow(
            label: 'NETWORK',
            value: 'Polygon Mainnet',
            monospace: true,
          ),
          const SizedBox(height: 8),
          const InfoRow(
            label: 'TOKEN',
            value: 'ERC-721 #4829',
            monospace: true,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Text('TX HASH', style: AppTextStyles.label),
          const SizedBox(height: 6),
          SelectableText(
            '0x71c8d4f209c3ae812db97a561a0c6ebd77f5a2f488b9e3d12a7c0e58b24f3a9f',
            style: AppTextStyles.mono.copyWith(
              fontSize: 11,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

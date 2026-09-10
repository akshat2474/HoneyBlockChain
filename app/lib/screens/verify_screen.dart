import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/hexagon_painter.dart';
import '../widgets/vercel_card.dart';
import '../widgets/vercel_button.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN 3: Consumer Batch Verification
// ═════════════════════════════════════════════════════════════════════════════

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _controller = TextEditingController(text: 'HC-2026-0847');
  bool _verified = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    FocusScope.of(context).unfocus();
    setState(() => _verified = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Authentic HoneyChain batch record located.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = MockData.featuredBatches.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: HexGridBackground(cellSize: 40, opacity: 0.04),
              ),
            ),
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
                        Text(
                          'Consumer Verification',
                          style: AppTextStyles.pageTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Trace honey from hive to bottle.',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 20),

                        // Search bar
                        _SearchRow(
                          controller: _controller,
                          onVerify: _verify,
                        ),

                        if (_verified) ...[
                          // Provenance dossier
                          const SectionLabel('Provenance dossier'),
                          _ProvenanceCard(batch: batch),

                          // Lab purity matrix
                          const SectionLabel('Lab purity matrix'),
                          _LabMatrix(),

                          // Blockchain ledger
                          const SectionLabel('Polygon verification ledger'),
                          _BlockchainLedger(batch: batch),
                        ] else ...[
                          const SizedBox(height: 40),
                          _ScanPrompt(),
                        ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Row
// ─────────────────────────────────────────────────────────────────────────────

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onVerify});
  final TextEditingController controller;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'BATCH ID / SCAN RESULT',
              labelStyle: AppTextStyles.label,
              prefixIcon: const Icon(Icons.search, size: 19, color: AppColors.textMuted),
            ),
            onSubmitted: (_) => onVerify(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onVerify,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: AppColors.canvas,
            shape: const RoundedRectangleBorder(
              borderRadius: AppConstants.smallRadius,
            ),
            fixedSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.arrow_forward, size: 20),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan Prompt (no results state)
// ─────────────────────────────────────────────────────────────────────────────

class _ScanPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VercelCard(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.document_scanner_outlined,
              size: 44, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Ready to verify', style: AppTextStyles.cardHeading),
          const SizedBox(height: 4),
          Text(
            'Enter a batch ID or scan a QR code above.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provenance Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProvenanceCard extends StatelessWidget {
  const _ProvenanceCard({required this.batch});
  final HoneyBatch batch;

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pure Raw ${batch.floralSource} Honey',
                      style: AppTextStyles.sectionHeading,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Batch #${batch.id}',
                      style: AppTextStyles.mono,
                    ),
                  ],
                ),
              ),
              const TokenBadge(),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          InfoRow(label: 'BEEKEEPER', value: MockData.beekeeper.name),
          const SizedBox(height: 8),
          InfoRow(label: 'ORIGIN', value: batch.origin),
          const SizedBox(height: 8),
          const InfoRow(
            label: 'ATTESTATION',
            value: 'KVIC Honey Mission verified',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lab Purity Matrix
// ─────────────────────────────────────────────────────────────────────────────

class _LabMatrix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final results = MockData.labResults;

    return VercelCard(
      child: Column(
        children: List.generate(results.length, (i) {
          return Column(
            children: [
              LabRow(
                metric: results[i].metric,
                result: results[i].result,
                detail: results[i].detail,
                passed: results[i].passed,
              ),
              if (i < results.length - 1)
                const Divider(height: 20, color: AppColors.border),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Blockchain Ledger Card
// ─────────────────────────────────────────────────────────────────────────────

class _BlockchainLedger extends StatelessWidget {
  const _BlockchainLedger({required this.batch});
  final HoneyBatch batch;

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRANSACTION HASH', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  batch.transactionHash,
                  style: AppTextStyles.mono.copyWith(fontSize: 11),
                ),
              ),
              IconButton(
                tooltip: 'Copy transaction hash',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: batch.transactionHash),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction hash copied.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined, size: 18),
                color: AppColors.textMuted,
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          const InfoRow(
              label: 'NETWORK', value: 'Polygon Mainnet', monospace: true),
          const SizedBox(height: 8),
          const InfoRow(
              label: 'TOKEN', value: 'ERC-721 HoneyNFT', monospace: true),
          const SizedBox(height: 14),
          SecondaryButton(
            label: 'View on Polygonscan',
            icon: Icons.open_in_new,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Polygonscan explorer link prepared.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/hexagon_painter.dart';
import '../widgets/vercel_card.dart';
import '../widgets/vercel_button.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN 4: Beekeeper & Admin Management Portal
// ═════════════════════════════════════════════════════════════════════════════

class BeekeeperScreen extends StatefulWidget {
  const BeekeeperScreen({super.key});

  @override
  State<BeekeeperScreen> createState() => _BeekeeperScreenState();
}

class _BeekeeperScreenState extends State<BeekeeperScreen> {
  final _quantityController = TextEditingController(text: '5.0');
  String _selectedHive = 'Hive #03';
  String _selectedSource = 'Multifloral';
  bool _committed = false;

  static const _sources = ['Mustard', 'Acacia', 'Multifloral', 'Eucalyptus'];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _commitBatch() {
    FocusScope.of(context).unfocus();
    setState(() => _committed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Batch signed and committed to Polygon.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = MockData.beekeeper;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: HexGridBackground(cellSize: 45, opacity: 0.04),
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
                          'Beekeeper Portal',
                          style: AppTextStyles.pageTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hive intelligence · Batch minting · Identity',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 24),

                        // Identity card
                        _IdentityCard(profile: profile),
                        const SizedBox(height: 24),

                        // Hive telemetry
                        const SectionLabel('Hive #03 telemetry'),
                        _TelemetryGrid(isWide: isWide),
                        const SizedBox(height: 8),

                        // Diagnostics
                        const SectionLabel('Server-side diagnostics'),
                        const _DiagnosticsCard(),
                        const SizedBox(height: 8),

                        // Batch minting form
                        const SectionLabel('Create new batch'),
                        _BatchMintForm(
                          quantityController: _quantityController,
                          selectedHive: _selectedHive,
                          selectedSource: _selectedSource,
                          sources: _sources,
                          onHiveChanged: (v) =>
                              setState(() => _selectedHive = v),
                          onSourceChanged: (v) =>
                              setState(() => _selectedSource = v),
                          onCommit: _commitBatch,
                        ),

                        if (_committed) ...[
                          const SizedBox(height: 12),
                          _CommitReceipt(
                            hive: _selectedHive,
                            quantity: _quantityController.text,
                            source: _selectedSource,
                          ),
                        ],

                        const SizedBox(height: 32),
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
// Beekeeper Identity Card
// ─────────────────────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});
  final BeekeeperProfile profile;

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      borderColor: AppColors.amber.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusDot(color: AppColors.green),
              const SizedBox(width: 8),
              Text(
                'IDENTITY VERIFIED',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.green, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(profile.name, style: AppTextStyles.sectionHeading),
          const SizedBox(height: 4),
          Text(profile.beneficiaryId, style: AppTextStyles.mono),
          const Divider(height: 24, color: AppColors.border),
          InfoRow(label: 'CLUSTER', value: profile.cluster),
          const SizedBox(height: 8),
          InfoRow(
            label: 'HIVES',
            value: '${profile.activeHives} Active',
            valueColor: AppColors.green,
          ),
          const SizedBox(height: 8),
          InfoRow(
            label: 'WALLET',
            value: profile.walletAddress,
            monospace: true,
          ),
          const SizedBox(height: 8),
          InfoRow(
            label: 'BATCHES',
            value: '${profile.totalBatches} on-chain',
            monospace: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hive Telemetry Grid
// ─────────────────────────────────────────────────────────────────────────────

class _TelemetryGrid extends StatelessWidget {
  const _TelemetryGrid({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: MockData.telemetry.map((reading) {
            return SizedBox(
              width: cardWidth,
              child: _TelemetryCard(reading: reading),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({required this.reading});
  final TelemetryReading reading;

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(
                color: reading.healthy ? AppColors.green : AppColors.red,
              ),
              const SizedBox(width: 6),
              Icon(reading.icon, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reading.label,
                  style: AppTextStyles.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                reading.value,
                style: AppTextStyles.stat.copyWith(fontSize: 22),
              ),
              const SizedBox(width: 3),
              Text(
                reading.unit,
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reading.note,
            style: AppTextStyles.mono.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diagnostics Card
// ─────────────────────────────────────────────────────────────────────────────

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard();

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      child: Column(
        children: [
          _DiagRow(
            label: 'HEALTH INDEX',
            value: '94/100',
            caption: 'Brood stability verified',
            color: AppColors.green,
          ),
          const Divider(height: 20, color: AppColors.border),
          _DiagRow(
            label: 'SWARM PROBABILITY',
            value: '4%',
            caption: 'Low risk',
            color: AppColors.green,
          ),
          const Divider(height: 20, color: AppColors.border),
          _DiagRow(
            label: 'HARVEST FORECAST',
            value: '4 DAYS',
            caption: 'Optimal harvest window',
            color: AppColors.amber,
          ),
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  const _DiagRow({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(caption, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Text(
          value,
          style: AppTextStyles.stat.copyWith(
            color: color,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Batch Minting Form
// ─────────────────────────────────────────────────────────────────────────────

class _BatchMintForm extends StatelessWidget {
  const _BatchMintForm({
    required this.quantityController,
    required this.selectedHive,
    required this.selectedSource,
    required this.sources,
    required this.onHiveChanged,
    required this.onSourceChanged,
    required this.onCommit,
  });

  final TextEditingController quantityController;
  final String selectedHive;
  final String selectedSource;
  final List<String> sources;
  final ValueChanged<String> onHiveChanged;
  final ValueChanged<String> onSourceChanged;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MINT BATCH', style: AppTextStyles.cardHeading),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedHive,
            dropdownColor: AppColors.card,
            decoration: InputDecoration(
              labelText: 'HIVE SELECTOR',
              labelStyle: AppTextStyles.label,
            ),
            items: List.generate(
              8,
              (i) => DropdownMenuItem(
                value: 'Hive #${(i + 1).toString().padLeft(2, '0')}',
                child: Text(
                  'Hive #${(i + 1).toString().padLeft(2, '0')}',
                  style: AppTextStyles.mono
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
            onChanged: (v) => onHiveChanged(v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: quantityController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'HARVEST QUANTITY',
              labelStyle: AppTextStyles.label,
              suffixText: 'kg',
              suffixStyle: AppTextStyles.mono,
            ),
          ),
          const SizedBox(height: 16),
          Text('FLORAL SOURCE', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources
                .map((s) => _SourceChip(
                      label: s,
                      selected: selectedSource == s,
                      onPressed: () => onSourceChanged(s),
                    ))
                .toList(),
          ),
          const Divider(height: 28, color: AppColors.border),
          const InfoRow(
            label: 'LOCKED GPS',
            value: '27.1751° N, 78.0421° E',
            monospace: true,
          ),
          const SizedBox(height: 8),
          const InfoRow(
            label: 'UTC TIME',
            value: '2026-09-07 08:14:32 UTC',
            monospace: true,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Sign & Commit to Polygon',
            icon: Icons.lock_outline,
            onPressed: onCommit,
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: AppConstants.smallRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber : AppColors.inset,
          borderRadius: AppConstants.smallRadius,
          border: Border.all(
            color: selected ? AppColors.amber : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.mono.copyWith(
            fontSize: 12,
            color: selected ? AppColors.canvas : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Commit Receipt
// ─────────────────────────────────────────────────────────────────────────────

class _CommitReceipt extends StatelessWidget {
  const _CommitReceipt({
    required this.hive,
    required this.quantity,
    required this.source,
  });

  final String hive;
  final String quantity;
  final String source;

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      borderColor: AppColors.green.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusDot(color: AppColors.green),
              const SizedBox(width: 8),
              Text(
                'COMMIT CONFIRMED',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.green,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('HC-2026-0847', style: AppTextStyles.stat),
          const SizedBox(height: 12),
          InfoRow(label: 'PAYLOAD', value: '$hive · $quantity kg · $source'),
          const SizedBox(height: 8),
          const InfoRow(
            label: 'GAS COST',
            value: '0.002 MATIC / ₹0.04',
            monospace: true,
          ),
          const SizedBox(height: 8),
          const InfoRow(
            label: 'BLOCK',
            value: '#5829104',
            monospace: true,
          ),
          const SizedBox(height: 8),
          const InfoRow(
            label: 'TX HASH',
            value: '0x71c8...3a9f',
            monospace: true,
          ),
        ],
      ),
    );
  }
}

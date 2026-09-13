import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/vercel_card.dart';
import '../widgets/vercel_button.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});
  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  String? _selectedBatch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return SingleChildScrollView(
          padding: AppConstants.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Lab Portal', style: AppTextStyles.pageTitle),
                      const SizedBox(width: 12),
                      Text('NABL Accredited Lab #MHL-2901',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  if (isWide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _PendingQueue(
                            selectedBatch: _selectedBatch,
                            onSelect: (b) => setState(() => _selectedBatch = b),
                          )),
                          Container(
                            width: 1, color: AppColors.border,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          Expanded(flex: 6, child: _LabForm(batchId: _selectedBatch)),
                        ],
                      ),
                    )
                  else
                    Column(children: [
                      _PendingQueue(
                        selectedBatch: _selectedBatch,
                        onSelect: (b) => setState(() => _selectedBatch = b),
                      ),
                      const SizedBox(height: AppConstants.sectionSpacing),
                      _LabForm(batchId: _selectedBatch),
                    ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PendingQueue extends StatelessWidget {
  const _PendingQueue({required this.selectedBatch, required this.onSelect});
  final String? selectedBatch;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PENDING QUEUE', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppConstants.cardRadius,
          ),
          child: Column(
            children: MockData.featuredBatches.asMap().entries.map((e) {
              final batch = e.value;
              final isSelected = selectedBatch == batch.id;
              final isLast = e.key == MockData.featuredBatches.length - 1;
              return GestureDetector(
                onTap: () => onSelect(batch.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cardHover : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                          color: isSelected ? AppColors.textPrimary : Colors.transparent,
                          width: 3),
                      bottom: isLast ? BorderSide.none : AppConstants.borderSide,
                    ),
                    borderRadius: isLast
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6))
                        : BorderRadius.zero,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch.id, style: AppTextStyles.mono.copyWith(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(batch.origin, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LabForm extends StatelessWidget {
  const _LabForm({this.batchId});
  final String? batchId;

  @override
  Widget build(BuildContext context) {
    if (batchId == null) return _EmptyState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RESULTS FOR $batchId', style: AppTextStyles.label),
        const SizedBox(height: 12),
        VercelCard(
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'NMR PURITY (%)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'MOISTURE (%)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'HMF (mg/kg)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'POLLEN COUNT (grains/g)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Text('NABL CERTIFICATE', style: AppTextStyles.label),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  borderRadius: AppConstants.smallRadius,
                  border: Border.all(
                    color: AppColors.borderHi,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(children: [
                  const Icon(Icons.upload_file_outlined, size: 28, color: AppColors.textMuted),
                  const SizedBox(height: 10),
                  Text('Drop PDF or click to upload', style: AppTextStyles.bodySmall),
                ]),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Sign & Submit to Blockchain',
                icon: Icons.fingerprint_outlined,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lab results submitted to smart contract.')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: BoxDecoration(
        borderRadius: AppConstants.cardRadius,
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.science_outlined, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No batch selected', style: AppTextStyles.cardHeading),
          const SizedBox(height: 6),
          Text('Select a batch from the queue to enter test results.',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

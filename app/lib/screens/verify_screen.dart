import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/verify_reveal.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});
  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _controller = TextEditingController();
  bool _verified = false;

  void _verify() {
    if (_controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _verified = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batch = MockData.featuredBatches.first;
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
                  Text('Verify Batch', style: AppTextStyles.pageTitle),
                  const SizedBox(width: 12),
                  Text('Scan QR or enter batch ID',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: AppConstants.sectionSpacing),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. HC-2026-0847',
                        prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_outlined,
                              size: 18, color: AppColors.textSecondary),
                          tooltip: 'Simulate QR Scan',
                          onPressed: () {
                            _controller.text = 'HC-2026-0847';
                            _verify();
                          },
                        ),
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.canvas,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppConstants.smallRadius),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text('Verify', style: AppTextStyles.cardHeading.copyWith(color: AppColors.canvas)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.sectionSpacing),
              if (_verified) ...[
                VerifyReveal(
                  batch: batch,
                  beekeeper: MockData.beekeeper,
                ),
              ] else
                _ScanPrompt(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppConstants.cardRadius,
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Ready to verify', style: AppTextStyles.cardHeading),
          const SizedBox(height: 6),
          Text('Enter a batch ID above or tap the scanner icon.',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}


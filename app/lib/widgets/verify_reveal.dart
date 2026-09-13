import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/vercel_card.dart';
import '../widgets/vercel_button.dart';

class VerifyReveal extends StatefulWidget {
  const VerifyReveal({super.key, required this.batch, required this.beekeeper});
  final HoneyBatch batch;
  final BeekeeperProfile beekeeper;

  @override
  State<VerifyReveal> createState() => _VerifyRevealState();
}

class _VerifyRevealState extends State<VerifyReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  final List<_TypedLine> _lines = [];
  final _allLines = [
    'querying polygon rpc...',
    'locating transaction hash...',
    'resolving ipfs cid...',
    'downloading metadata...',
    'computing sha256 hash...',
    'comparing against on-chain hash...',
    'hash match ✓',
  ];
  int _lineIndex = 0;
  bool _revealed = false;

  static const _typeDelay = Duration(milliseconds: 520);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _scheduleNextLine();
  }

  void _scheduleNextLine() {
    if (_lineIndex >= _allLines.length) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _revealed = true);
      });
      return;
    }
    Future.delayed(_typeDelay, () {
      if (!mounted) return;
      setState(() => _lines.add(_TypedLine(text: _allLines[_lineIndex])));
      _lineIndex++;
      _scheduleNextLine();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: _revealed ? _RevealedContent(batch: widget.batch, beekeeper: widget.beekeeper)
                       : _TerminalPrelude(lines: _lines),
    );
  }
}

class _TerminalPrelude extends StatelessWidget {
  const _TerminalPrelude({required this.lines});
  final List<_TypedLine> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verifying...', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppConstants.cardRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '> ${l.text}',
                        style: AppTextStyles.mono.copyWith(
                          color: l.text.contains('✓')
                              ? AppColors.green
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _RevealedContent extends StatefulWidget {
  const _RevealedContent({required this.batch, required this.beekeeper});
  final HoneyBatch batch;
  final BeekeeperProfile beekeeper;

  @override
  State<_RevealedContent> createState() => _RevealedContentState();
}

class _RevealedContentState extends State<_RevealedContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  final List<int> _visibleRows = [];
  final _dataRows = [
    ['FLORAL SOURCE', ''],
    ['ORIGIN', ''],
    ['BEEKEEPER', ''],
    ['NMR PURITY', ''],
    ['MOISTURE', ''],
    ['CERTIFIED BY', 'NABL Lab #MHL-2901'],
  ];
  bool _showTx = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _scheduleRows();
  }

  void _scheduleRows() {
    for (var i = 0; i < _dataRows.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 80), () {
        if (mounted) setState(() => _visibleRows.add(i));
      });
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showTx = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthenticHeader(batchId: widget.batch.id),
            const SizedBox(height: 16),
            VercelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._dataRows.asMap().entries.map((e) {
                    final visible = _visibleRows.contains(e.key);
                    final values = [
                      widget.batch.floralSource,
                      widget.batch.origin,
                      widget.beekeeper.name,
                      '${widget.batch.purityIndex}%',
                      '17.2%',
                      'NABL Lab #MHL-2901',
                    ];
                    return AnimatedOpacity(
                      opacity: visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.value[0], style: AppTextStyles.label),
                            Text(values[e.key],
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_showTx) ...[
                    const Divider(height: 20, color: AppColors.border),
                    Text('TX HASH', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    AnimatedOpacity(
                      opacity: _showTx ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: SelectableText(
                        widget.batch.transactionHash,
                        style: AppTextStyles.mono.copyWith(
                            color: AppColors.blue, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'View on Polygonscan',
                      icon: Icons.open_in_new,
                      onPressed: () {},
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticHeader extends StatelessWidget {
  const _AuthenticHeader({required this.batchId});
  final String batchId;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.green, width: 1.5),
          ),
          child: const Icon(Icons.check, color: AppColors.green, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AUTHENTIC', style: AppTextStyles.label.copyWith(color: AppColors.green, letterSpacing: 1.2)),
            Text(batchId, style: AppTextStyles.mono),
          ],
        ),
      ],
    );
  }
}

class _TypedLine {
  const _TypedLine({required this.text});
  final String text;
}

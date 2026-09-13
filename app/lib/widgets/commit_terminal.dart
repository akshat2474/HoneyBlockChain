import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/honey_theme.dart';

class CommitStep {
  const CommitStep({
    required this.index,
    required this.label,
    required this.delayMs,
    required this.durationMs,
    this.value,
    this.isInfo = false,
  });

  final int index;
  final String label;
  final int delayMs;
  final int durationMs;
  final String? value;
  final bool isInfo;
}

const _steps = [
  CommitStep(index: 1, label: 'building metadata payload',    delayMs: 400,  durationMs: 12),
  CommitStep(index: 2, label: 'uploading to ipfs via pinata', delayMs: 900,  durationMs: 847),
  CommitStep(index: 0, label: 'cid: QmXk9f4...aB7c3',        delayMs: 1200, durationMs: 0, isInfo: true),
  CommitStep(index: 3, label: 'sha256 hashing metadata',      delayMs: 1400, durationMs: 2),
  CommitStep(index: 4, label: 'constructing contract calldata',delayMs: 1700, durationMs: 8),
  CommitStep(index: 5, label: 'signing with beekeeper wallet', delayMs: 2000, durationMs: 31),
  CommitStep(index: 6, label: 'broadcasting to polygon amoy', delayMs: 2500, durationMs: 0),
  CommitStep(index: 7, label: 'waiting for confirmation',     delayMs: 3200, durationMs: 0),
  CommitStep(index: 8, label: 'block #5829104 confirmed',     delayMs: 5800, durationMs: 3200),
  CommitStep(index: 9, label: 'batch HC-2026-0848 sealed on-chain', delayMs: 6200, durationMs: 0),
];

class CommitTerminal extends StatefulWidget {
  const CommitTerminal({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<CommitTerminal> createState() => _CommitTerminalState();
}

class _CommitTerminalState extends State<CommitTerminal>
    with SingleTickerProviderStateMixin {
  final List<_RenderedStep> _rendered = [];
  final List<Timer> _timers = [];
  bool _done = false;
  late AnimationController _fadeController;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _scheduleSteps();
  }

  void _scheduleSteps() {
    for (final step in _steps) {
      final t = Timer(Duration(milliseconds: step.delayMs), () {
        if (!mounted) return;
        setState(() => _rendered.add(_RenderedStep(step: step, pending: !step.isInfo && step.index >= 6)));
      });
      _timers.add(t);
    }

    final confirmTimer = Timer(const Duration(milliseconds: 5800), () {
      if (!mounted) return;
      setState(() {
        for (final r in _rendered) {
          if (r.step.index >= 6) r.pending = false;
        }
      });
    });
    _timers.add(confirmTimer);

    final doneTimer = Timer(const Duration(milliseconds: 7000), () {
      if (!mounted) return;
      setState(() => _done = true);
    });
    _timers.add(doneTimer);
  }

  @override
  void dispose() {
    for (final t in _timers) { t.cancel(); }
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: AppColors.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _done ? AppColors.green : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _done ? 'COMMITTED TO POLYGON' : 'COMMITTING...',
                    style: AppTextStyles.label.copyWith(
                      color: _done ? AppColors.green : AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ]),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: _rendered.length,
                    itemBuilder: (_, i) => _StepLine(rendered: _rendered[i]),
                  ),
                ),
                if (_done) ...[
                  const Divider(color: AppColors.border, height: 32),
                  _Receipt(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: widget.onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.canvas,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppConstants.smallRadius),
                      ),
                      child: Text('Done', style: AppTextStyles.cardHeading.copyWith(color: AppColors.canvas)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenderedStep {
  _RenderedStep({required this.step, required this.pending});
  final CommitStep step;
  bool pending;
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.rendered});
  final _RenderedStep rendered;

  @override
  Widget build(BuildContext context) {
    final step = rendered.step;
    final isInfo = step.isInfo;
    final isPending = rendered.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (!isInfo)
            Text(
              '[${step.index.toString().padLeft(2, '0')}]',
              style: AppTextStyles.mono.copyWith(
                  color: AppColors.textMuted, fontSize: 12),
            )
          else
            Text(
              '    ',
              style: AppTextStyles.mono.copyWith(fontSize: 12),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label,
              style: AppTextStyles.mono.copyWith(
                color: isInfo ? AppColors.blue : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          if (!isInfo)
            isPending
                ? _PendingDots()
                : step.durationMs > 0
                    ? Text(
                        '✓  ${step.durationMs}ms',
                        style: AppTextStyles.mono.copyWith(
                            color: AppColors.green, fontSize: 11),
                      )
                    : Text(
                        '✓',
                        style: AppTextStyles.mono.copyWith(
                            color: AppColors.green, fontSize: 11),
                      ),
        ],
      ),
    );
  }
}

class _PendingDots extends StatefulWidget {
  @override
  State<_PendingDots> createState() => _PendingDotsState();
}

class _PendingDotsState extends State<_PendingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..addListener(() {
        if (_ctrl.isCompleted) {
          setState(() => _frame = (_frame + 1) % 4);
          _ctrl.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * (_frame + 1);
    return Text(
      '⏳  $dots',
      style: AppTextStyles.mono.copyWith(color: AppColors.textMuted, fontSize: 11),
    );
  }
}

class _Receipt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECEIPT', style: AppTextStyles.label.copyWith(letterSpacing: 1)),
        const SizedBox(height: 12),
        _infoRow('BATCH ID', 'HC-2026-0848'),
        const SizedBox(height: 6),
        _infoRow('BLOCK', '#5829104'),
        const SizedBox(height: 6),
        _infoRow('GAS', '0.002 MATIC'),
        const SizedBox(height: 6),
        _infoRow('TX', '0x71c8...3a9f'),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(value, style: AppTextStyles.mono.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

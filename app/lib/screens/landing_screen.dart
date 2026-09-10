import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/hex_stat_card.dart';
import '../widgets/vercel_card.dart';
import '../widgets/vercel_button.dart';
import '../widgets/honey_art.dart';
import '../widgets/hex_distortion_canvas.dart';
import '../widgets/flipping_words.dart';
import '../widgets/blur_fade_in.dart';
import '../widgets/gradient_underglow.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN 1: Landing & Overview Dashboard (Interactive Hexagon Distortion)
// ═════════════════════════════════════════════════════════════════════════════

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, this.onNavigate});
  final ValueChanged<int>? onNavigate;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ValueNotifier<Offset?> _pointerNotifier = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _pointerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return MouseRegion(
          opaque: false,
          onHover: (e) => _pointerNotifier.value = e.localPosition,
          onExit: (_) => _pointerNotifier.value = null,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _pointerNotifier.value = e.localPosition,
            onPointerMove: (e) => _pointerNotifier.value = e.localPosition,
            onPointerUp: (_) => _pointerNotifier.value = null,
            child: Stack(
              children: [
                // 1. Full-screen Interactive Hexagonal Honeycomb Distortion Mesh
                Positioned.fill(
                  child: HexDistortionCanvas(
                    pointerNotifier: _pointerNotifier,
                    cellSize: isWide ? 44 : 32,
                    distortionRadius: 180,
                    distortionStrength: 52,
                  ),
                ),

                // 2. Scrollable Content Layer
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
                            _HeroSection(
                              isWide: isWide,
                              onNavigate: widget.onNavigate,
                            ),
                            const SizedBox(height: 48),
                            _HexMetricGrid(isWide: isWide),
                            const SizedBox(height: 52),
                            _FeaturedBatches(isWide: isWide),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Section with Flipping Words & Blur Fade-In
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isWide, this.onNavigate});
  final bool isWide;
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),

        // Blur Fade-In: Pill Badge
        BlurFadeIn(
          delay: const Duration(milliseconds: 100),
          child: const PillBadge(
            text: 'KVIC Honey Blockchain Provenance →',
            dotColor: AppColors.amber,
            textColor: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Blur Fade-In + Flipping Words Headline
        BlurFadeIn(
          delay: const Duration(milliseconds: 200),
          child: Column(
            crossAxisAlignment:
                isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Text(
                'Immutable Provenance for',
                textAlign: isWide ? TextAlign.left : TextAlign.center,
                style: AppTextStyles.heroTitle.copyWith(
                  fontSize: isWide ? 44 : 30,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              FlippingWords(
                words: const [
                  'Pure Honey',
                  'KVIC Harvests',
                  'Tested Batches',
                  'Verified Hives',
                ],
                textStyle: AppTextStyles.heroTitle.copyWith(
                  fontSize: isWide ? 48 : 34,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Blur Fade-In: Subtitle
        BlurFadeIn(
          delay: const Duration(milliseconds: 350),
          child: Text(
            'Every jar of KVIC honey is cryptographically sealed on Polygon.\nTrace origin, purity, and beekeeper identity with a single scan.',
            textAlign: isWide ? TextAlign.left : TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),

        // Blur Fade-In: Search input + CTA buttons
        BlurFadeIn(
          delay: const Duration(milliseconds: 450),
          child: Column(
            crossAxisAlignment:
                isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              _BatchSearchBar(onNavigate: onNavigate),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
                children: [
                  SizedBox(
                    width: isWide ? null : double.infinity,
                    child: PrimaryButton(
                      label: 'Verify Honey Batch',
                      icon: Icons.verified_outlined,
                      onPressed: () => onNavigate?.call(2),
                      expand: !isWide,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? null : double.infinity,
                    child: SecondaryButton(
                      label: 'View Blockchain Ledger',
                      icon: Icons.token_outlined,
                      onPressed: () => onNavigate?.call(1),
                      expand: !isWide,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Batch Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BatchSearchBar extends StatelessWidget {
  const _BatchSearchBar({this.onNavigate});
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter Batch ID (e.g. KVIC-2026-88A9)',
                hintStyle: AppTextStyles.bodySmall,
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.inset,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: const OutlineInputBorder(
                  borderRadius: AppConstants.smallRadius,
                  borderSide: AppConstants.borderSide,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppConstants.smallRadius,
                  borderSide: AppConstants.borderSide,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppConstants.smallRadius,
                  borderSide: BorderSide(color: AppColors.amber),
                ),
              ),
              onSubmitted: (_) => onNavigate?.call(2),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => onNavigate?.call(2),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Honeycomb Metric Grid with Ambient Gradient Underglow & Counters
// ─────────────────────────────────────────────────────────────────────────────

class _HexMetricGrid extends StatelessWidget {
  const _HexMetricGrid({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NETWORK OVERVIEW', style: AppTextStyles.label),
        const SizedBox(height: 16),
        GradientUnderglow(
          child: Wrap(
            spacing: isWide ? 10 : 6,
            runSpacing: isWide ? 10 : 6,
            alignment: WrapAlignment.center,
            children: [
              HexStatCard(
                label: 'BATCHES VERIFIED',
                value: '12,450+',
                numericTarget: 12450,
                suffix: '+',
                icon: Icons.verified_outlined,
                accentColor: AppColors.green,
                size: isWide ? 155 : 130,
              ),
              HexStatCard(
                label: 'PURITY INDEX',
                value: '99.8%',
                numericTarget: 99.8,
                suffix: '%',
                decimals: 1,
                icon: Icons.science_outlined,
                accentColor: AppColors.amber,
                size: isWide ? 155 : 130,
              ),
              HexStatCard(
                label: 'BEEKEEPERS',
                value: '842',
                numericTarget: 842,
                icon: Icons.groups_outlined,
                accentColor: AppColors.blue,
                size: isWide ? 155 : 130,
              ),
              HexStatCard(
                label: 'BLOCK HEIGHT',
                value: '#5.8M',
                numericTarget: 5.8,
                prefix: '#',
                suffix: 'M',
                decimals: 1,
                icon: Icons.token_outlined,
                accentColor: AppColors.textMuted,
                size: isWide ? 155 : 130,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Honey Batches with Interactive Hover
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedBatches extends StatelessWidget {
  const _FeaturedBatches({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('RECENTLY VERIFIED', style: AppTextStyles.label),
            const Spacer(),
            Text('View all →',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.amber, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 14),
        ...MockData.featuredBatches.map(
          (batch) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BatchCard(batch: batch),
          ),
        ),
      ],
    );
  }
}

class _BatchCard extends StatefulWidget {
  const _BatchCard({required this.batch});
  final HoneyBatch batch;

  @override
  State<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<_BatchCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -3.0 : 0.0, 0.0),
        child: VercelCard(
          borderColor: _isHovered
              ? AppColors.amber.withValues(alpha: 0.5)
              : AppColors.border,
          color: _isHovered ? AppColors.inset : AppColors.card,
          child: Row(
            children: [
              // Hex icon with subtle pulse
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isHovered
                        ? AppColors.amber
                        : AppColors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: const Center(
                  child: HoneyArt(type: HoneyArtType.jar, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              // Batch info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.batch.id, style: AppTextStyles.cardHeading),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.batch.floralSource} · ${widget.batch.origin}',
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status + purity
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusDot(
                        color: widget.batch.status == BatchStatus.verified
                            ? AppColors.green
                            : AppColors.amber,
                        size: 6,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.batch.status.name.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: widget.batch.status == BatchStatus.verified
                              ? AppColors.green
                              : AppColors.amber,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.batch.purityIndex}%',
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

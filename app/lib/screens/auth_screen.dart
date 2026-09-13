import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  UserRole? _hovered;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Row(
            children: [
              Expanded(
                flex: isWide ? 55 : 100,
                child: _LeftPanel(
                  hovered: _hovered,
                  onHover: (r) => setState(() => _hovered = r),
                  onSelect: _login,
                ),
              ),
              if (isWide)
                Container(width: 1, color: AppColors.border),
              if (isWide)
                Expanded(
                  flex: 45,
                  child: const _RightPanel(),
                ),
            ],
          );
        },
      ),
    );
  }

  void _login(UserRole role) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HoneyChainShell(role: role)));
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.hovered,
    required this.onHover,
    required this.onSelect,
  });
  final UserRole? hovered;
  final ValueChanged<UserRole?> onHover;
  final ValueChanged<UserRole> onSelect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.inset,
                      borderRadius: AppConstants.smallRadius,
                      border: Border.all(color: AppColors.borderHi),
                    ),
                    alignment: Alignment.center,
                    child: Text('HC',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 10),
                  Text('HoneyChain', style: AppTextStyles.brand),
                ],
              ),
              const SizedBox(height: 48),
              Text('Decentralized\nhoney provenance.', style: AppTextStyles.heroTitle.copyWith(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'Every batch. Every hive. Every test. Sealed on Polygon.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 48),
              Text('CONTINUE AS', style: AppTextStyles.label),
              const SizedBox(height: 16),
              _RoleCard(
                role: UserRole.consumer,
                label: 'Consumer',
                description: 'Scan QR codes, verify honey provenance.',
                hovered: hovered,
                onHover: onHover,
                onSelect: onSelect,
              ),
              const SizedBox(height: 8),
              _RoleCard(
                role: UserRole.beekeeper,
                label: 'Beekeeper',
                description: 'Register batches, sync IoT telemetry.',
                hovered: hovered,
                onHover: onHover,
                onSelect: onSelect,
              ),
              const SizedBox(height: 8),
              _RoleCard(
                role: UserRole.lab,
                label: 'Lab Technician',
                description: 'Upload NABL results, certify purity.',
                hovered: hovered,
                onHover: onHover,
                onSelect: onSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.label,
    required this.description,
    required this.hovered,
    required this.onHover,
    required this.onSelect,
  });

  final UserRole role;
  final String label;
  final String description;
  final UserRole? hovered;
  final ValueChanged<UserRole?> onHover;
  final ValueChanged<UserRole> onSelect;

  @override
  Widget build(BuildContext context) {
    final isActive = hovered == role;
    return MouseRegion(
      onEnter: (_) => onHover(role),
      onExit: (_) => onHover(null),
      child: GestureDetector(
        onTap: () => onSelect(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? AppColors.cardHover : AppColors.card,
            borderRadius: AppConstants.cardRadius,
            border: Border(
              left: BorderSide(
                  color: isActive ? AppColors.textPrimary : AppColors.border,
                  width: 3),
              top: AppConstants.borderSide,
              right: AppConstants.borderSide,
              bottom: AppConstants.borderSide,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.cardHeading),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward,
                  size: 16,
                  color: isActive ? AppColors.textPrimary : AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NETWORK STATS', style: AppTextStyles.label),
              const SizedBox(height: 32),
              _BigStat(value: '12,450', label: 'Verified Batches'),
              const SizedBox(height: 32),
              _BigStat(value: '842', label: 'Active Beekeepers'),
              const SizedBox(height: 32),
              _BigStat(value: '99.8%', label: 'Average Purity Index'),
              const SizedBox(height: 32),
              _BigStat(value: '5.8M', label: 'Block Height'),
              const SizedBox(height: 48),
              const Divider(color: AppColors.border),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Polygon Mainnet · Live',
                      style: AppTextStyles.mono.copyWith(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              Text('0x3F...9A1B',
                  style: AppTextStyles.mono.copyWith(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.stat),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

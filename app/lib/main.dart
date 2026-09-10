import 'package:flutter/material.dart';
import 'theme/honey_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/traceability_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/beekeeper_screen.dart';
import 'widgets/animated_nav_pill.dart';

void main() {
  runApp(const HoneyChainApp());
}

class HoneyChainApp extends StatelessWidget {
  const HoneyChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoneyChain — KVIC Blockchain Provenance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HoneyChainShell(),
    );
  }
}

class HoneyChainShell extends StatefulWidget {
  const HoneyChainShell({super.key});

  @override
  State<HoneyChainShell> createState() => _HoneyChainShellState();
}

class _HoneyChainShellState extends State<HoneyChainShell> {
  int _selectedIndex = 0;

  final _titles = const [
    'Overview & Network',
    'Supply Chain Traceability',
    'Batch Verification',
    'Beekeeper Portal',
  ];

  static const _navItems = [
    NavItemData(
      label: 'Overview',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    NavItemData(
      label: 'Traceability',
      icon: Icons.alt_route_outlined,
      selectedIcon: Icons.alt_route_rounded,
    ),
    NavItemData(
      label: 'Verify',
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified_rounded,
    ),
    NavItemData(
      label: 'Beekeeper',
      icon: Icons.sensors_outlined,
      selectedIcon: Icons.sensors_rounded,
    ),
  ];

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final views = [
      LandingScreen(onNavigate: _onNavigate),
      const TraceabilityScreen(),
      const VerifyScreen(),
      const BeekeeperScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBody: false, // Docked firmly at bottom without content overlap
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppColors.canvas.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // Hexagon Honey Mark with Amber Glow
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.hexagon_outlined,
                size: 18,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'HONEYCHAIN',
              style: AppTextStyles.brand,
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: AppColors.border),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _titles[_selectedIndex],
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: AppConstants.pillRadius,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Polygon #5.8M',
                    style: AppTextStyles.mono.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: views,
      ),
      // Full-width docked bottom navbar with smooth hover effects
      bottomNavigationBar: AnimatedBottomNavbar(
        items: _navItems,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigate,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'theme/honey_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/traceability_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/beekeeper_screen.dart';
import 'screens/lab_screen.dart';

enum UserRole { consumer, beekeeper, lab }

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
      home: const AuthScreen(),
    );
  }
}

class HoneyChainShell extends StatefulWidget {
  const HoneyChainShell({super.key, required this.role});
  final UserRole role;

  @override
  State<HoneyChainShell> createState() => _HoneyChainShellState();
}

class _HoneyChainShellState extends State<HoneyChainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _views;
  late final List<NavigationDestination> _destinations;
  late final List<String> _titles;

  @override
  void initState() {
    super.initState();
    _views = [
      LandingScreen(onNavigate: _onNavigate),
      const ExploreScreen(),
      const TraceabilityScreen(),
    ];
    
    _destinations = [
      const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Overview'),
      const NavigationDestination(
          icon: Icon(Icons.hexagon_outlined),
          selectedIcon: Icon(Icons.hexagon_rounded),
          label: 'Explore'),
      const NavigationDestination(
          icon: Icon(Icons.alt_route_outlined),
          selectedIcon: Icon(Icons.alt_route_rounded),
          label: 'Traceability'),
    ];
    
    _titles = ['Overview', 'Global Honeycomb', 'Traceability'];

    switch (widget.role) {
      case UserRole.consumer:
        _views.add(const VerifyScreen());
        _destinations.add(const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Verify'));
        _titles.add('Verify Batch');
        break;
      case UserRole.beekeeper:
        _views.add(const BeekeeperScreen());
        _destinations.add(const NavigationDestination(
            icon: Icon(Icons.hive_outlined),
            selectedIcon: Icon(Icons.hive_rounded),
            label: 'Beekeeper'));
        _titles.add('Beekeeper Portal');
        break;
      case UserRole.lab:
        _views.add(const LabScreen());
        _destinations.add(const NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science_rounded),
            label: 'Lab'));
        _titles.add('Lab Portal');
        break;
    }
  }

  void _onNavigate(int index) {
    if (index < 0 || index >= _views.length) return;
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goBack() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  bool get _canGoBack => _selectedIndex != 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        leading: _canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textMuted),
                tooltip: 'Go back',
                onPressed: _goBack,
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                'HC',
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.canvas,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('HoneyChain', style: AppTextStyles.brand),
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: AppColors.border),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _titles[_selectedIndex],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 200,
            height: 32,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inset,
              borderRadius: AppConstants.smallRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Search batch ID...',
                      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.symmetric(vertical: 14),
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
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Polygon',
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigate,
        destinations: _destinations,
        backgroundColor: AppColors.canvas,
        indicatorColor: AppColors.inset,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

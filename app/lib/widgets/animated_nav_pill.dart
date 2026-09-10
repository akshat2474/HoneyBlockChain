import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedBottomNavbar — Full-Width Docked Navbar with Smooth Hover Effects
// ─────────────────────────────────────────────────────────────────────────────

class NavItemData {
  const NavItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AnimatedBottomNavbar extends StatefulWidget {
  const AnimatedBottomNavbar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<AnimatedBottomNavbar> createState() => _AnimatedBottomNavbarState();
}

class _AnimatedBottomNavbarState extends State<AnimatedBottomNavbar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.items.length, (i) {
              final item = widget.items[i];
              final isSelected = widget.selectedIndex == i;
              final isHovered = _hoveredIndex == i && !isSelected;

              return Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = i),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onDestinationSelected(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.inset
                            : (isHovered
                                ? AppColors.inset.withValues(alpha: 0.6)
                                : Colors.transparent),
                        borderRadius: AppConstants.smallRadius,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.borderLight
                              : (isHovered
                                  ? AppColors.border
                                  : Colors.transparent),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            size: 19,
                            color: isSelected
                                ? AppColors.textPrimary
                                : (isHovered
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 10,
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : (isHovered
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

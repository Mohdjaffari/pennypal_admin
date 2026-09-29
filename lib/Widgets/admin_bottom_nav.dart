import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/admin_provider.dart';

class PennyPalBottomNav extends StatelessWidget {
  final VoidCallback onQuickActionPressed;

  const PennyPalBottomNav({
    super.key,
    required this.onQuickActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final currentIndex = provider.currentNavIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => provider.setNavIndex(0),
              ),
              _buildNavItem(
                icon: Icons.people_alt_rounded,
                label: 'Users',
                isSelected: currentIndex == 1,
                onTap: () => provider.setNavIndex(1),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: onQuickActionPressed,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.pinkGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPink.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              _buildNavItem(
                icon: Icons.menu_book_rounded,
                label: 'Content',
                isSelected: currentIndex == 2 || currentIndex == 3 || currentIndex == 6,
                onTap: () => provider.setNavIndex(2),
              ),
              _buildNavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Reports',
                isSelected: currentIndex == 7,
                onTap: () => provider.setNavIndex(7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.accentPink : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accentPink : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

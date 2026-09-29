import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dashboard_controller.dart';
import '../core/constants/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminDrawer extends StatelessWidget {
  final bool isPermanent;

  const AdminDrawer({
    super.key,
    this.isPermanent = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final dashCtrl = context.watch<DashboardController>();
    final selectedIndex = provider.currentNavIndex;

    final isLive = dashCtrl.isLiveConnected;
    final totalUsersCount = isLive ? '${dashCtrl.stats.totalUsers}' : '${provider.totalUsersCount}';
    final learningCount = isLive ? '${dashCtrl.stats.totalLearning}' : '${provider.learningContents.length}';
    final faqsCount = isLive ? '${dashCtrl.stats.totalFaqs}' : '${provider.faqs.length}';
    final categoriesCount = isLive ? '${dashCtrl.stats.totalCategories}' : '${provider.categories.length}';

    final content = Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: AppColors.border.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'favicon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.spa_rounded,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'PennyPal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentPink,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Admin Control Center',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                children: [
                  _sectionHeader('OVERVIEW'),
                  _drawerItem(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    isSelected: selectedIndex == 0,
                  ),
                  _drawerItem(
                    context: context,
                    index: 1,
                    icon: Icons.people_alt_rounded,
                    title: 'User Management',
                    badge: totalUsersCount,
                    isSelected: selectedIndex == 1,
                  ),

                  const SizedBox(height: 16),
                  _sectionHeader('CONTENT & PORTAL'),
                  _drawerItem(
                    context: context,
                    index: 2,
                    icon: Icons.menu_book_rounded,
                    title: 'Learning Content',
                    badge: learningCount,
                    isSelected: selectedIndex == 2,
                  ),
                  _drawerItem(
                    context: context,
                    index: 3,
                    icon: Icons.quiz_rounded,
                    title: 'FAQs Management',
                    badge: faqsCount,
                    isSelected: selectedIndex == 3,
                  ),
                  _drawerItem(
                    context: context,
                    index: 6,
                    icon: Icons.category_rounded,
                    title: 'User Categories',
                    badge: categoriesCount,
                    isSelected: selectedIndex == 6,
                  ),

                  const SizedBox(height: 16),
                  _sectionHeader('COMMUNICATIONS'),
                  _drawerItem(
                    context: context,
                    index: 10,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications & Alerts',
                    badge: provider.unreadNotificationsCount > 0
                        ? '${provider.unreadNotificationsCount} New'
                        : null,
                    badgeColor: AppColors.primary,
                    isSelected: selectedIndex == 10,
                  ),
                  _drawerItem(
                    context: context,
                    index: 4,
                    icon: Icons.mail_outline_rounded,
                    title: 'Contact Messages',
                    badge: provider.newContactMessagesCount > 0
                        ? '${provider.newContactMessagesCount} New'
                        : null,
                    badgeColor: AppColors.accentPink,
                    isSelected: selectedIndex == 4,
                  ),
                  _drawerItem(
                    context: context,
                    index: 5,
                    icon: Icons.rate_review_outlined,
                    title: 'User Feedbacks',
                    badge: provider.pendingFeedbacksCount > 0
                        ? '${provider.pendingFeedbacksCount}'
                        : null,
                    badgeColor: AppColors.warning,
                    isSelected: selectedIndex == 5,
                  ),

                  const SizedBox(height: 16),
                  _sectionHeader('AUDIT & ANALYTICS'),
                  _drawerItem(
                    context: context,
                    index: 7,
                    icon: Icons.assessment_rounded,
                    title: 'User Reports',
                    badge: '${provider.generatedReports.length}',
                    isSelected: selectedIndex == 7,
                  ),

                  const SizedBox(height: 16),
                  _sectionHeader('SETTINGS & ACCOUNT'),
                  _drawerItem(
                    context: context,
                    index: 8,
                    icon: Icons.account_circle_outlined,
                    title: 'Admin Profile',
                    isSelected: selectedIndex == 8,
                  ),
                  _drawerItem(
                    context: context,
                    index: 9,
                    icon: Icons.settings_outlined,
                    title: 'System Settings',
                    isSelected: selectedIndex == 9,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        if (!isPermanent) Navigator.pop(context);
                        provider.logout();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (isPermanent) {
      return content;
    }
    return Drawer(child: content);
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
    String? badge,
    Color? badgeColor,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            context.read<AdminProvider>().setNavIndex(index);
            if (!isPermanent) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? (isSelected ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: badgeColor != null ? Colors.white : (isSelected ? Colors.white : AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_bottom_nav.dart';
import 'dashboard/dashboard_screen.dart';
import 'users/users_screen.dart';
import 'learning/learning_screen.dart';
import 'faqs/faqs_screen.dart';
import 'contact_us/contact_us_screen.dart';
import 'feedbacks/feedbacks_screen.dart';
import 'categories/categories_screen.dart';
import 'reports/reports_screen.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
import 'notifications/notifications_screen.dart';
import 'auth/login_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Learning Content';
      case 3:
        return 'Frequently Asked Questions';
      case 4:
        return 'Contact Us Inquiries';
      case 5:
        return 'User Feedbacks';
      case 6:
        return 'User Categories';
      case 7:
        return 'Reports & Analytics';
      case 8:
        return 'Admin Profile';
      case 9:
        return 'Platform Settings';
      case 10:
        return 'Notifications & Platform Alerts';
      default:
        return 'Admin Portal';
    }
  }

  Widget _getCurrentScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const UsersScreen();
      case 2:
        return const LearningScreen();
      case 3:
        return const FaqsScreen();
      case 4:
        return const ContactUsScreen();
      case 5:
        return const FeedbacksScreen();
      case 6:
        return const CategoriesScreen();
      case 7:
        return const ReportsScreen();
      case 8:
        return const ProfileScreen();
      case 9:
        return const SettingsScreen();
      case 10:
        return const NotificationsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    if (!provider.isAuthenticated) {
      return const LoginScreen();
    }
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isDesktop ? null : const AdminDrawer(isPermanent: false),
      appBar: PennyPalAdminAppBar(
        title: _getPageTitle(provider.currentNavIndex),
        onMenuPressed: isDesktop
            ? null
            : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Row(
        children: [
          if (isDesktop) const AdminDrawer(isPermanent: true),

          Expanded(
            child: SafeArea(
              left: false,
              right: false,
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _getCurrentScreen(provider.currentNavIndex),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : PennyPalBottomNav(
              onQuickActionPressed: () => _showQuickActionBottomSheet(context, provider),
            ),
    );
  }

  void _showQuickActionBottomSheet(BuildContext context, AdminProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Admin Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fast-track creation across PennyPal platform',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _quickActionTile(
                    ctx,
                    icon: Icons.person_add_rounded,
                    label: 'Add User',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.setNavIndex(1);
                    },
                  ),
                  _quickActionTile(
                    ctx,
                    icon: Icons.post_add_rounded,
                    label: 'New Article',
                    color: AppColors.accentPink,
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.setNavIndex(2);
                    },
                  ),
                  _quickActionTile(
                    ctx,
                    icon: Icons.quiz_rounded,
                    label: 'Add FAQ',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.setNavIndex(3);
                    },
                  ),
                  _quickActionTile(
                    ctx,
                    icon: Icons.category_rounded,
                    label: 'New Category',
                    color: AppColors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.setNavIndex(6);
                    },
                  ),
                  _quickActionTile(
                    ctx,
                    icon: Icons.assessment_rounded,
                    label: 'Audit Report',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.setNavIndex(7);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/dashboard_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/admin_provider.dart';
import 'widgets/stat_card.dart';
import 'widgets/analytics_charts.dart';
import '../../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final dashCtrl = context.watch<DashboardController>();
    final stats = dashCtrl.stats;

    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 28,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(context, provider, dashCtrl),

            const SizedBox(height: 24),

            _buildStatCardsGrid(context, provider, dashCtrl),

            const SizedBox(height: 24),

            _buildQuickShortcuts(context, provider, dashCtrl),

            const SizedBox(height: 24),

            if (!isDesktop) ...[
              AnalyticsOverviewChart(
                period: 'This Week',
                registrationTrend: stats.weeklyRegistrations,
                totalUsers: stats.totalUsers,
              ),
              const SizedBox(height: 20),
              CategoryDonutChart(slices: stats.categorySlices),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AnalyticsOverviewChart(
                      period: 'This Week',
                      registrationTrend: stats.weeklyRegistrations,
                      totalUsers: stats.totalUsers,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: CategoryDonutChart(slices: stats.categorySlices),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),

            if (!isDesktop) ...[
              _buildRecentUsersCard(context, provider, dashCtrl),
              const SizedBox(height: 20),
              _buildPendingInquiriesCard(context, provider, dashCtrl),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildRecentUsersCard(context, provider, dashCtrl),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _buildPendingInquiriesCard(context, provider, dashCtrl),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildWelcomeBanner(
    BuildContext context,
    AdminProvider provider,
    DashboardController dashCtrl,
  ) {
    final nowFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final isOnline = dashCtrl.isLiveConnected;
    final totalAccounts = dashCtrl.stats.totalUsers;

    final screenW = MediaQuery.of(context).size.width;
    final isCompactWidth = screenW < 520;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompactWidth ? 16 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, color: Color(0xFF60A5FA), size: 14),
                          SizedBox(width: 5),
                          Text(
                            'ADMIN CONSOLE',
                            style: TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF10B981).withValues(alpha: 0.18)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOnline
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOnline ? 'Firestore Live Synced' : 'Connecting Database...',
                            style: TextStyle(
                              color: isOnline ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'PennyPal Master Dashboard',
                  style: TextStyle(
                    fontSize: isCompactWidth ? 19 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$nowFormatted • Managing $totalAccounts registered users and real-time financial tracking metrics.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: dashCtrl.isLoading
                ? null
                : () {
                    dashCtrl.fetchDashboardData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Expanded(child: Text('Dashboard refreshed with latest Firestore data!')),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
            icon: dashCtrl.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Sync Database Now',
          ),
          if (!isCompactWidth) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    Color(0xFF6366F1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCardsGrid(
    BuildContext context,
    AdminProvider provider,
    DashboardController dashCtrl,
  ) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 360
        ? 1
        : width < 700
            ? 2
            : width < 1100
                ? 3
                : 4;
    final double mainAxisExtent = width < 360 ? 128 : 152;

    final stats = dashCtrl.stats;
    final isOnline = dashCtrl.isLiveConnected;

    final totalUsers = isOnline ? stats.totalUsers : (stats.totalUsers > 0 ? stats.totalUsers : provider.users.length);
    final activeUsers = isOnline ? stats.activeUsers : (stats.activeUsers > 0 ? stats.activeUsers : provider.activeUsersCount);
    final blockedUsers = isOnline ? stats.blockedUsers : (stats.blockedUsers > 0 ? stats.blockedUsers : provider.blockedUsersCount);
    final totalCategories = isOnline ? stats.totalCategories : (stats.totalCategories > 0 ? stats.totalCategories : provider.categories.length);
    final totalLearning = isOnline ? stats.totalLearning : (stats.totalLearning > 0 ? stats.totalLearning : provider.learningContents.length);
    final featuredLearning = isOnline
        ? stats.featuredLearning
        : (stats.featuredLearning > 0 ? stats.featuredLearning : provider.learningContents.where((l) => l.isFeatured).length);
    final totalFaqs = isOnline ? stats.totalFaqs : (stats.totalFaqs > 0 ? stats.totalFaqs : provider.faqs.length);
    final totalInquiries = stats.totalInquiries > 0 ? stats.totalInquiries : provider.contactMessages.length;
    final pendingInquiries = stats.pendingInquiries > 0 ? stats.pendingInquiries : provider.newContactMessagesCount;

    final activePercentage = totalUsers > 0 ? ((activeUsers / totalUsers) * 100).toInt() : 100;

    final cards = [
      StatCard(
        title: 'Total Users',
        value: '$totalUsers',
        subtitle: 'Firestore registered accounts',
        icon: Icons.people_alt_rounded,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primarySoft,
        badgeText: 'Live',
        isPositiveBadge: true,
        onTap: () => provider.setNavIndex(1),
      ),
      StatCard(
        title: 'Active Accounts',
        value: '$activeUsers',
        subtitle: '$blockedUsers Restricted • $activePercentage% Active',
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF10B981),
        iconBgColor: const Color(0xFFECFDF5),
        badgeText: '$activePercentage%',
        isPositiveBadge: true,
        onTap: () => provider.setNavIndex(1),
      ),
      StatCard(
        title: 'Learning Guides',
        value: '$totalLearning',
        subtitle: '$featuredLearning Featured guides published',
        icon: Icons.menu_book_rounded,
        iconColor: AppColors.accentPink,
        iconBgColor: AppColors.accentPinkLight,
        badgeText: 'Guides',
        isPositiveBadge: true,
        onTap: () => provider.setNavIndex(2),
      ),
      StatCard(
        title: 'User Categories',
        value: '$totalCategories',
        subtitle: '${stats.expenseCategories} Expense • ${stats.incomeCategories} Income',
        icon: Icons.category_rounded,
        iconColor: AppColors.purple,
        iconBgColor: AppColors.purpleLight,
        badgeText: 'Online',
        isPositiveBadge: true,
        onTap: () => provider.setNavIndex(6),
      ),
      StatCard(
        title: 'FAQs Knowledge Base',
        value: '$totalFaqs',
        subtitle: 'Answers available to students',
        icon: Icons.help_outline_rounded,
        iconColor: const Color(0xFF0EA5E9),
        iconBgColor: const Color(0xFFE0F2FE),
        badgeText: 'Help',
        isPositiveBadge: true,
        onTap: () => provider.setNavIndex(3),
      ),
      StatCard(
        title: 'Support Inquiries',
        value: '$totalInquiries',
        subtitle: '$pendingInquiries Pending admin review',
        icon: Icons.mail_outline_rounded,
        iconColor: const Color(0xFFF59E0B),
        iconBgColor: const Color(0xFFFFFBEB),
        badgeText: pendingInquiries > 0 ? '$pendingInquiries New' : 'Cleared',
        isPositiveBadge: pendingInquiries == 0,
        onTap: () => provider.setNavIndex(4),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: mainAxisExtent,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildQuickShortcuts(
    BuildContext context,
    AdminProvider provider,
    DashboardController dashCtrl,
  ) {
    final stats = dashCtrl.stats;
    final isOnline = dashCtrl.isLiveConnected;
    final totalUsers = isOnline ? stats.totalUsers : (stats.totalUsers > 0 ? stats.totalUsers : provider.users.length);
    final totalLearning = isOnline ? stats.totalLearning : (stats.totalLearning > 0 ? stats.totalLearning : provider.learningContents.length);
    final totalFaqs = isOnline ? stats.totalFaqs : (stats.totalFaqs > 0 ? stats.totalFaqs : provider.faqs.length);
    final totalCategories = isOnline ? stats.totalCategories : (stats.totalCategories > 0 ? stats.totalCategories : provider.categories.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Management Hub',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _shortcutButton(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Users ($totalUsers)',
                color: AppColors.primary,
                onTap: () => provider.setNavIndex(1),
              ),
              const SizedBox(width: 10),
              _shortcutButton(
                icon: Icons.library_books_rounded,
                label: 'Learning ($totalLearning)',
                color: AppColors.accentPink,
                onTap: () => provider.setNavIndex(2),
              ),
              const SizedBox(width: 10),
              _shortcutButton(
                icon: Icons.help_outline_rounded,
                label: 'FAQs ($totalFaqs)',
                color: const Color(0xFF10B981),
                onTap: () => provider.setNavIndex(3),
              ),
              const SizedBox(width: 10),
              _shortcutButton(
                icon: Icons.category_rounded,
                label: 'Categories ($totalCategories)',
                color: AppColors.purple,
                onTap: () => provider.setNavIndex(6),
              ),
              const SizedBox(width: 10),
              _shortcutButton(
                icon: Icons.analytics_rounded,
                label: 'Analytics & Reports',
                color: const Color(0xFFF59E0B),
                onTap: () => provider.setNavIndex(7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shortcutButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUsersCard(
    BuildContext context,
    AdminProvider provider,
    DashboardController dashCtrl,
  ) {
    final recentUsers = dashCtrl.stats.recentUsers;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Recently Joined Users',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => provider.setNavIndex(1),
                child: const Text(
                  'View All Users',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          if (recentUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No users registered yet.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = recentUsers[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                    onBackgroundImageError: user.avatarUrl.isNotEmpty ? (exception, stackTrace) {} : null,
                    child: Text(
                      user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    user.email,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      user.isBlocked ? StatusBadge.blocked() : StatusBadge.active(),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                          color: user.isBlocked ? AppColors.success : AppColors.danger,
                          size: 19,
                        ),
                        tooltip: user.isBlocked ? 'Unblock User' : 'Block User',
                        onPressed: () async {
                          final ok = await dashCtrl.toggleBlockUser(user);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  user.isBlocked
                                      ? 'User ${user.name} has been unblocked.'
                                      : 'User ${user.name} has been suspended.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPendingInquiriesCard(
    BuildContext context,
    AdminProvider provider,
    DashboardController dashCtrl,
  ) {
    final recentInquiries = dashCtrl.stats.recentInquiries;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.support_agent_rounded, size: 20, color: AppColors.accentPink),
                  SizedBox(width: 8),
                  Text(
                    'Support & Inquiries',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => provider.setNavIndex(4),
                child: const Text(
                  'Manage Inquiries',
                  style: TextStyle(
                    color: AppColors.accentPink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          if (recentInquiries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No pending contact inquiries 🎉',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...recentInquiries.map((msg) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              msg.senderName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            StatusBadge.pending(label: 'Inquiry'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.subject,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

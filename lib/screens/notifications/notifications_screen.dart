import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/notification_model.dart';
import '../../providers/admin_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _confirmClearAll(BuildContext context, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'This will permanently delete all notifications from the shared database. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.clearAllNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared.'),
                    backgroundColor: AppColors.textPrimary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final isDesktop = Responsive.isDesktop(context);
    final notifications = provider.filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 400;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmall ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(context, provider, isDesktop),
                const SizedBox(height: 24),

                _buildMetricSummaryCards(context, provider),
                const SizedBox(height: 24),

                _buildFiltersAndSearchBar(context, provider),
                const SizedBox(height: 16),

                if (provider.isNotificationsLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (notifications.isEmpty)
                  _buildEmptyState(context, provider)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _buildNotificationCard(context, provider, notif);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(
    BuildContext context,
    AdminProvider provider,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, headerConstraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback & Inquiries Alerts',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Live real-time alerts for customer support inquiries and user satisfaction reviews.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: provider.unreadNotificationsCount == 0
                      ? null
                      : () => provider.markAllNotificationsAsRead(),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Mark All Read'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmClearAll(context, provider),
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricSummaryCards(
    BuildContext context,
    AdminProvider provider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;
        final isMobile = constraints.maxWidth < 460;
        final cardWidth = isMobile
            ? (constraints.maxWidth - 10) / 2
            : (isSmall
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4);

        return Wrap(
          spacing: isMobile ? 10 : 12,
          runSpacing: isMobile ? 10 : 12,
          children: [
            _metricCard(
              title: 'Total Inquiries & Reviews',
              value: '${provider.totalInquiryFeedbackNotificationsCount}',
              subtitle: 'From active users',
              icon: Icons.mark_chat_unread_rounded,
              color: AppColors.primary,
              width: cardWidth,
            ),
            _metricCard(
              title: 'Contact Messages',
              value: '${provider.contactInquiriesNotificationCount}',
              subtitle: 'Support queue',
              icon: Icons.contact_support_rounded,
              color: AppColors.accentPink,
              width: cardWidth,
            ),
            _metricCard(
              title: 'User Feedbacks',
              value: '${provider.userReviewsNotificationCount}',
              subtitle: 'App ratings & reviews',
              icon: Icons.star_rate_rounded,
              color: const Color(0xFFD97706),
              width: cardWidth,
            ),
            _metricCard(
              title: 'Pending Action',
              value: '${provider.unreadNotificationsCount}',
              subtitle: 'Requires review',
              icon: Icons.pending_actions_rounded,
              color: AppColors.purple,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    final isCompact = width < 180;
    return Container(
      width: width,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isCompact ? 18 : 22),
          ),
          SizedBox(width: isCompact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isCompact ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSearchBar(
    BuildContext context,
    AdminProvider provider,
  ) {
    final tabs = ['All', 'Contact Inquiries', 'User Reviews', 'Unread'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => provider.setNotificationSearchQuery(val),
                  decoration: InputDecoration(
                    hintText:
                        'Search inquiries and feedback by keyword, user, or topic...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.setNotificationSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                final isSelected = provider.notificationFilter == tab;
                int count = 0;
                if (tab == 'All') {
                  count = provider.totalInquiryFeedbackNotificationsCount;
                } else if (tab == 'Contact Inquiries') {
                  count = provider.contactInquiriesNotificationCount;
                } else if (tab == 'User Reviews') {
                  count = provider.userReviewsNotificationCount;
                } else if (tab == 'Unread') {
                  count = provider.unreadNotificationsCount;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tab),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (val) {
                      provider.setNotificationFilter(tab);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AdminProvider provider,
    NotificationModel notif,
  ) {
    final typeColor = notif.color;
    final typeIcon = notif.icon;

    return Container(
      decoration: BoxDecoration(
        color: notif.isRead ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notif.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.35),
          width: notif.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: notif.isRead
                ? Colors.black.withValues(alpha: 0.02)
                : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 22),
            ),
            const SizedBox(width: 14),

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notif.typeLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ),

                      if (!notif.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentPink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notif.timeAgo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: notif.isRead
                          ? FontWeight.w600
                          : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (_hasDirectNavigation(notif.type))
                        OutlinedButton.icon(
                          onPressed: () {
                            if (!notif.isRead) {
                              provider.markNotificationAsRead(notif.id);
                            }
                            _navigateForNotification(context, provider, notif);
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: Text(_getNavigationLabel(notif.type)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primaryLight,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!notif.isRead)
                            IconButton(
                              tooltip: 'Mark as read',
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              onPressed: () =>
                                  provider.markNotificationAsRead(notif.id),
                            ),

                          IconButton(
                            tooltip: 'Delete notification',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                provider.deleteNotification(notif.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasDirectNavigation(NotificationType type) {
    return type == NotificationType.contactMessage ||
        type == NotificationType.feedbackReceived ||
        type == NotificationType.userRegistered ||
        type == NotificationType.learningPublished;
  }

  String _getNavigationLabel(NotificationType type) {
    switch (type) {
      case NotificationType.contactMessage:
        return 'View Inquiries';
      case NotificationType.feedbackReceived:
        return 'Review Feedback';
      case NotificationType.userRegistered:
        return 'View User Directory';
      case NotificationType.learningPublished:
        return 'View Learning Content';
      default:
        return 'View Details';
    }
  }

  void _navigateForNotification(
    BuildContext context,
    AdminProvider provider,
    NotificationModel notif,
  ) {
    switch (notif.type) {
      case NotificationType.contactMessage:
        provider.setNavIndex(4);
        break;
      case NotificationType.feedbackReceived:
        provider.setNavIndex(5);
        break;
      case NotificationType.userRegistered:
        provider.setNavIndex(1);
        break;
      case NotificationType.learningPublished:
        provider.setNavIndex(2);
        break;
      default:
        break;
    }
  }

  Widget _buildEmptyState(BuildContext context, AdminProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Inquiries or Feedback Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'When users submit feedback or send messages through Contact Us, real-time alerts will appear here.\nYou can navigate directly to inquiries and feedbacks.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => provider.setNavIndex(4),
                icon: const Icon(Icons.contact_support_rounded, size: 16),
                label: const Text('Go to Inquiries'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => provider.setNavIndex(5),
                icon: const Icon(Icons.star_rate_rounded, size: 16),
                label: const Text('Go to Feedbacks'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFD97706)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

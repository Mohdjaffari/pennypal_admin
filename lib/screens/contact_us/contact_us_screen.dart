import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/contact_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  String _selectedFilter = 'All'; // All, New, In Progress, Resolved
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().refreshContactMessages();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(AdminProvider provider) async {
    setState(() => _isRefreshing = true);
    await provider.refreshContactMessages();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    final filteredMessages = provider.contactMessages.where((m) {
      if (_selectedFilter == 'New' && m.status != ContactStatus.newMsg) return false;
      if (_selectedFilter == 'In Progress' && m.status != ContactStatus.inProgress) return false;
      if (_selectedFilter == 'Resolved' && m.status != ContactStatus.resolved) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchesName = m.senderName.toLowerCase().contains(query);
        final matchesEmail = m.senderEmail.toLowerCase().contains(query);
        final matchesPhone = m.phone.toLowerCase().contains(query);
        final matchesSubject = m.subject.toLowerCase().contains(query);
        final matchesMessage = m.message.toLowerCase().contains(query);
        if (!matchesName && !matchesEmail && !matchesPhone && !matchesSubject && !matchesMessage) {
          return false;
        }
      }

      return true;
    }).toList();

    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildMetricsBanner(context, provider),
          _buildFilterToolbar(context, provider),
          Expanded(
            child: provider.isContactLoading && provider.contactMessages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredMessages.isEmpty
                    ? _buildEmptyState(provider)
                    : RefreshIndicator(
                        onRefresh: () => _handleRefresh(provider),
                        color: AppColors.primary,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 24,
                            vertical: 16,
                          ),
                          itemCount: filteredMessages.length,
                          itemBuilder: (context, index) {
                            final msg = filteredMessages[index];
                            return _buildMessageCard(context, msg, provider);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBanner(BuildContext context, AdminProvider provider) {
    final total = provider.contactMessages.length;
    final newCount = provider.newContactMessagesCount;
    final inProgressCount = provider.inProgressContactMessagesCount;
    final resolvedCount = provider.resolvedContactMessagesCount;
    final responseRate = provider.contactResponseRate.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 600;
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
                        child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Us Inquiries',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Live Firestore stream • Real-time customer support queue',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 16),
                        StatusBadge.active(label: 'Firestore Sync Active'),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Refresh from Database',
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                          onPressed: _isRefreshing ? null : () => _handleRefresh(provider),
                        ),
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StatusBadge.active(label: 'Firestore Sync Active'),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Refresh from Database',
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                          onPressed: _isRefreshing ? null : () => _handleRefresh(provider),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // KPI Stat Cards Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildKpiCard(
                  title: 'Total Messages',
                  value: '$total',
                  subtext: '$responseRate% response rate',
                  icon: Icons.all_inbox_rounded,
                  color: AppColors.primary,
                  isSelected: _selectedFilter == 'All',
                  onTap: () => setState(() => _selectedFilter = 'All'),
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  title: 'Pending (New)',
                  value: '$newCount',
                  subtext: newCount > 0 ? 'Requires attention' : 'Queue clear 🎉',
                  icon: Icons.markunread_mailbox_rounded,
                  color: AppColors.accentPink,
                  isSelected: _selectedFilter == 'New',
                  onTap: () => setState(() => _selectedFilter = 'New'),
                  badgeText: newCount > 0 ? 'NEW' : null,
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  title: 'In Progress',
                  value: '$inProgressCount',
                  subtext: 'Currently investigating',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                  isSelected: _selectedFilter == 'In Progress',
                  onTap: () => setState(() => _selectedFilter = 'In Progress'),
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  title: 'Resolved',
                  value: '$resolvedCount',
                  subtext: 'Closed & answered',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.success,
                  isSelected: _selectedFilter == 'Resolved',
                  onTap: () => setState(() => _selectedFilter = 'Resolved'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 175,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: color),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            Text(
              subtext,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToolbar(BuildContext context, AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by sender name, email, phone, subject or content...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      fillColor: AppColors.background,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Seed Database Button (if collection has 0 items or for testing)
              if (provider.contactMessages.isEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    final seeded = await provider.seedSampleContactMessages();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text('Populated $seeded realistic customer inquiries into Firestore!'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: const Text('Seed Sample Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', provider.contactMessages.length),
                const SizedBox(width: 8),
                _buildFilterChip('New', provider.newContactMessagesCount),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', provider.inProgressContactMessagesCount),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', provider.resolvedContactMessagesCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, ContactMessageModel msg, AdminProvider provider) {
    StatusBadge getBadge() {
      switch (msg.status) {
        case ContactStatus.newMsg:
          return StatusBadge.custom(
            label: 'New Inquiry',
            color: AppColors.accentPink,
            icon: Icons.mark_email_unread_rounded,
          );
        case ContactStatus.inProgress:
          return StatusBadge.custom(
            label: 'In Progress',
            color: AppColors.warning,
            icon: Icons.hourglass_top_rounded,
          );
        case ContactStatus.resolved:
          return StatusBadge.custom(
            label: 'Resolved',
            color: AppColors.success,
            icon: Icons.check_circle_outline_rounded,
          );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: msg.status == ContactStatus.newMsg
              ? AppColors.accentPink.withValues(alpha: 0.3)
              : AppColors.border,
          width: msg.status == ContactStatus.newMsg ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Email, Phone, Status & Quick Status Changer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: msg.status == ContactStatus.newMsg
                    ? AppColors.accentPinkLight
                    : AppColors.primarySoft,
                child: Text(
                  msg.senderInitials,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: msg.status == ContactStatus.newMsg
                        ? AppColors.accentPink
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            msg.senderName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        getBadge(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (msg.senderEmail.isNotEmpty)
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: msg.senderEmail));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 1),
                                  content: Text('Email copied to clipboard'),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  msg.senderEmail,
                                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        if (msg.phone.isNotEmpty)
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: msg.phone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 1),
                                  content: Text('Phone copied to clipboard'),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  msg.phone,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inquiry Subject & Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        msg.subject,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  msg.message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          // Admin Response Section
          if (msg.adminReply != null && msg.adminReply!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'PennyPal Admin Response:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                      const Spacer(),
                      if (msg.repliedAt != null)
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(msg.repliedAt!),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF059669)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    msg.adminReply!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF065F46),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Footer: Timestamp, Status Selector, and Actions
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${msg.timeAgo} • ${DateFormat('dd MMM yyyy, hh:mm a').format(msg.submittedAt)}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Status Dropdown
                  PopupMenuButton<ContactStatus>(
                    tooltip: 'Change Status',
                    onSelected: (newStatus) {
                      provider.updateContactStatus(msg.id, newStatus);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Text('Status updated to ${newStatus.name}'),
                        ),
                      );
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: ContactStatus.newMsg,
                        child: Text('Mark as New'),
                      ),
                      const PopupMenuItem(
                        value: ContactStatus.inProgress,
                        child: Text('Mark as In Progress'),
                      ),
                      const PopupMenuItem(
                        value: ContactStatus.resolved,
                        child: Text('Mark as Resolved'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reply Button
                  TextButton.icon(
                    onPressed: () => _showReplyDialog(context, msg, provider),
                    icon: const Icon(Icons.reply_rounded, size: 16),
                    label: Text(msg.adminReply != null ? 'Edit Reply' : 'Send Reply'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.danger,
                    tooltip: 'Delete Inquiry',
                    onPressed: () => _showDeleteConfirmDialog(context, msg, provider),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, ContactMessageModel msg, AdminProvider provider) {
    final replyCtrl = TextEditingController(text: msg.adminReply ?? '');
    ContactStatus newStatus = ContactStatus.resolved;

    // Quick templates to expedite response
    final templates = [
      'Thank you for reaching out! We are currently investigating this for you.',
      'Hello! Your issue has been resolved in our latest update. Please refresh the app.',
      'Thank you for contacting PennyPal. Could you please provide your registered phone number?',
      'We have addressed your inquiry. Please let us know if you need anything else!',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actionsOverflowButtonSpacing: 8,
          actionsOverflowAlignment: OverflowBarAlignment.end,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.reply_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reply to ${msg.senderName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      msg.senderEmail,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject: ${msg.subject}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.message,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Response Templates:',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: templates.map((tpl) {
                      return InkWell(
                        onTap: () {
                          replyCtrl.text = tpl;
                          setDialogState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            tpl.length > 38 ? '${tpl.substring(0, 38)}...' : tpl,
                            style: const TextStyle(fontSize: 11, color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: replyCtrl,
                    label: 'Official Admin Response',
                    maxLines: 4,
                    hintText: 'Type your official response to the user...',
                  ),
                  const SizedBox(height: 14),
                  const Text('Set Resolution Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ContactStatus>(
                    initialValue: newStatus,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ContactStatus.resolved,
                        child: Text(
                          'Resolved & Closed (Recommended)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ContactStatus.inProgress,
                        child: Text(
                          'In Progress (Follow-up needed)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ContactStatus.newMsg,
                        child: Text(
                          'Keep as New',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                    onChanged: (val) => setDialogState(() => newStatus = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            CustomButton(
              text: 'Save & Submit Response',
              height: 42,
              onPressed: () {
                if (replyCtrl.text.trim().isNotEmpty) {
                  provider.replyToContact(msg.id, replyCtrl.text.trim());
                  provider.updateContactStatus(msg.id, newStatus);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Response submitted and saved to Firestore!'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ContactMessageModel msg, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Inquiry?'),
        content: Text('Are you sure you want to permanently delete the inquiry from "${msg.senderName}"? This action removes it from Firestore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.deleteContactMessage(msg.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inquiry deleted successfully')),
              );
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdminProvider provider) {
    if (_searchQuery.isNotEmpty || _selectedFilter != 'All') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Inquiries Match Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try changing your search terms or filter selection.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                });
              },
              child: const Text('Clear All Filters'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Inquiries in Database',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your Firestore "contact_messages" collection currently has no entries.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final count = await provider.seedSampleContactMessages();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Successfully loaded $count realistic inquiries into Firestore!'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Seed Sample Customer Inquiries'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

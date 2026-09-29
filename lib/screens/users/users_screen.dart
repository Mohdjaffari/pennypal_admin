import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import 'add_user_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool isTableView = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final userCtrl = context.watch<UserController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: userCtrl.getUsersStream(),
        builder: (context, snapshot) {
          List<UserModel> allUsers = [];

          if (snapshot.hasData) {
            allUsers = snapshot.data!.docs.map((doc) {
              return UserModel.fromMap(doc.data(), docId: doc.id);
            }).toList();
          }

          final query = provider.userSearchQuery.toLowerCase();
          final filter = provider.userStatusFilter;

          final filteredUsers = allUsers.where((u) {
            final matchesSearch = query.isEmpty ||
                u.name.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query) ||
                u.phone.toLowerCase().contains(query) ||
                u.role.toLowerCase().contains(query);
            if (!matchesSearch) return false;

            if (filter == 'Active') return !u.isBlocked;
            if (filter == 'Blocked') return u.isBlocked;
            return true;
          }).toList();

          final totalCount = allUsers.length;
          final activeCount = allUsers.where((u) => !u.isBlocked).length;
          final blockedCount = allUsers.where((u) => u.isBlocked).length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'User Accounts Manager',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  StatusBadge.active(
                                    label: 'Firebase Connected',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Provision, verify, and monitor PennyPal user and student accounts synchronized with Firestore',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              onChanged: provider.setUserSearchQuery,
                              decoration: const InputDecoration(
                                hintText: 'Search users by name, email, phone, role...',
                                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CustomButton(
                          text: 'Add User',
                          icon: Icons.person_add_rounded,
                          height: 46,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddUserScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _filterChip(context, provider, 'All', totalCount),
                            _filterChip(context, provider, 'Active', activeCount),
                            _filterChip(context, provider, 'Blocked', blockedCount),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _viewToggleButton(
                                icon: Icons.table_chart_rounded,
                                label: 'Table',
                                isSelected: isTableView,
                                onTap: () => setState(() => isTableView = true),
                              ),
                              _viewToggleButton(
                                icon: Icons.grid_view_rounded,
                                label: 'Cards',
                                isSelected: !isTableView,
                                onTap: () => setState(() => isTableView = false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting && allUsers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredUsers.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.people_outline_rounded,
                            title: 'No Users Found',
                            subtitle: 'No user accounts match the current filter or search criteria.',
                            buttonText: 'Provision New User',
                            onButtonPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddUserScreen(),
                                ),
                              );
                            },
                          )
                        : isTableView
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: _buildUsersTable(context, filteredUsers, userCtrl, provider),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return _buildUserCard(context, user, userCtrl, provider);
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    AdminProvider provider,
    String label,
    int count,
  ) {
    final isSelected = provider.userStatusFilter == label;
    return InkWell(
      onTap: () => provider.setUserStatusFilter(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
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

  Widget _buildUsersTable(
    BuildContext context,
    List<UserModel> users,
    UserController userCtrl,
    AdminProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Accounts Directory',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Comprehensive registry with account management actions',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${users.length} Users Listed',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                dataRowMaxHeight: 68,
                dataRowMinHeight: 60,
                horizontalMargin: 20,
                columnSpacing: 28,
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text('USER PROFILE')),
                  DataColumn(label: Text('USER ID')),
                  DataColumn(label: Text('PHONE NUMBER')),
                  DataColumn(label: Text('ROLE')),
                  DataColumn(label: Text('JOINED DATE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: users.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primarySoft,
                              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                              onBackgroundImageError: user.avatarUrl.isNotEmpty ? (exception, stackTrace) {} : null,
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            user.id,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          user.phone,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.role,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          DateFormat('dd MMM yyyy').format(user.joinedDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      DataCell(
                        user.isBlocked ? StatusBadge.blocked() : StatusBadge.active(),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                              color: AppColors.textSecondary,
                              tooltip: 'View Profile Snapshot',
                              onPressed: () => _showUserDetailsDialog(context, user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: AppColors.primary,
                              tooltip: 'Edit User Info',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddUserScreen(user: user),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                                size: 18,
                              ),
                              color: user.isBlocked ? AppColors.success : AppColors.warning,
                              tooltip: user.isBlocked ? 'Unblock User' : 'Block User Account',
                              onPressed: () => _confirmBlockUser(context, userCtrl, provider, user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              color: AppColors.danger,
                              tooltip: 'Delete User Permanently',
                              onPressed: () => _confirmDeleteUser(context, userCtrl, provider, user),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserModel user,
    UserController userCtrl,
    AdminProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: user.isBlocked
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                onBackgroundImageError: user.avatarUrl.isNotEmpty ? (exception, stackTrace) {} : null,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        user.isBlocked ? StatusBadge.blocked() : StatusBadge.active(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${user.phone} • ${user.role}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _userAccountInfoCol(
                    'User ID',
                    user.id,
                    AppColors.primary,
                    Icons.badge_outlined,
                    isId: true,
                  ),
                ),
                Container(width: 1, height: 26, color: AppColors.border),
                Expanded(
                  child: _userAccountInfoCol(
                    'Account Role',
                    user.role,
                    AppColors.accentPink,
                    Icons.verified_user_outlined,
                  ),
                ),
                Container(width: 1, height: 26, color: AppColors.border),
                Expanded(
                  child: _userAccountInfoCol(
                    'App Activity',
                    '${user.totalTransactions} Actions',
                    AppColors.purple,
                    Icons.sync_alt_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Joined: ${DateFormat('dd MMM yyyy').format(user.joinedDate)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
                    color: AppColors.textSecondary,
                    tooltip: 'View Profile Snapshot',
                    onPressed: () => _showUserDetailsDialog(context, user),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.primary,
                    tooltip: 'Edit User Info',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddUserScreen(user: user),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                    icon: Icon(
                      user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                      size: 20,
                    ),
                    color: user.isBlocked ? AppColors.success : AppColors.warning,
                    tooltip: user.isBlocked ? 'Unblock User' : 'Block User Account',
                    onPressed: () => _confirmBlockUser(context, userCtrl, provider, user),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppColors.danger,
                    tooltip: 'Delete User Permanently',
                    onPressed: () => _confirmDeleteUser(context, userCtrl, provider, user),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userAccountInfoCol(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isId = false,
  }) {
    final displayValue = isId && value.length > 11
        ? '${value.substring(0, 5)}...${value.substring(value.length - 4)}'
        : value;

    return Tooltip(
      message: '$label: $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            displayValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }



  void _showUserDetailsDialog(
    BuildContext context,
    UserModel user,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySoft,
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              onBackgroundImageError: user.avatarUrl.isNotEmpty ? (exception, stackTrace) {} : null,
              child: Text(
                user.initials,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(user.role, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('User ID', user.id),
              _detailRow('Email', user.email),
              _detailRow('Phone', user.phone),
              _detailRow('Account Role', user.role),
              _detailRow('Account Status', user.isBlocked ? 'Blocked 🚫' : 'Active ✅'),
              _detailRow('Total Recorded Actions', '${user.totalTransactions} activities'),
              _detailRow('Registration Date', DateFormat('dd MMM yyyy, hh:mm a').format(user.joinedDate)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBlockUser(
    BuildContext context,
    UserController userCtrl,
    AdminProvider provider,
    UserModel user,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(user.isBlocked ? 'Unblock User?' : 'Block User?'),
        content: Text(
          user.isBlocked
              ? 'This will restore ${user.displayName}\'s access to PennyPal app and transaction syncing in Firebase.'
              : 'Blocking will restrict ${user.displayName} from adding expenses, budgets, or syncing with Penny AI.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isBlocked ? AppColors.success : AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await userCtrl.toggleBlockUser(user.id, user.isBlocked);
              provider.toggleBlockUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: user.isBlocked ? AppColors.warning : AppColors.success,
                    content: Text(user.isBlocked ? '${user.displayName} has been blocked in database.' : '${user.displayName} is now active.'),
                  ),
                );
              }
            },
            child: Text(user.isBlocked ? 'Unblock' : 'Confirm Block'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(
    BuildContext context,
    UserController userCtrl,
    AdminProvider provider,
    UserModel user,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete User Account?'),
        content: Text(
          'Are you sure you want to permanently delete ${user.displayName} (${user.email}) from Firebase database? This action is irreversible.',
        ),
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
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await userCtrl.deleteUser(user.id);
              provider.deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    content: Text(
                      success
                          ? '${user.displayName} was deleted from database.'
                          : 'Failed to delete user. Check permissions.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}

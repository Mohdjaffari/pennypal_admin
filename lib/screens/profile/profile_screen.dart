import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final profile = provider.adminProfile;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHero(context, profile, provider),

            const SizedBox(height: 20),

            if (isDesktop) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildAccountInfoCard(context, profile, provider),
                        const SizedBox(height: 20),
                        _buildSecurityCard(context, profile, provider),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildPermissionsCard(context),
                        const SizedBox(height: 20),
                        _buildSessionCard(context, profile),
                        const SizedBox(height: 20),
                        _buildLogoutCard(context, provider),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildAccountInfoCard(context, profile, provider),
              const SizedBox(height: 20),
              _buildSecurityCard(context, profile, provider),
              const SizedBox(height: 20),
              _buildPermissionsCard(context),
              const SizedBox(height: 20),
              _buildSessionCard(context, profile),
              const SizedBox(height: 20),
              _buildLogoutCard(context, provider),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero(
    BuildContext context,
    dynamic profile,
    AdminProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => _pickAndUploadAvatar(context, provider),
                      borderRadius: BorderRadius.circular(50),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2.5),
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primarySoft,
                              backgroundImage: profile.avatarUrl.isNotEmpty ? NetworkImage(profile.avatarUrl) : null,
                              onBackgroundImageError: profile.avatarUrl.isNotEmpty ? (exception, stackTrace) {} : null,
                              child: profile.avatarUrl.isEmpty
                                  ? Text(
                                      profile.name.isNotEmpty ? profile.name.substring(0, 1).toUpperCase() : 'A',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.accentPink,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                                ),
                                child: const Text(
                                  'SUPERUSER',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF93C5FD),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${profile.role} • ${profile.department}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _heroBadge(Icons.shield_outlined, 'Tier-1 Security', const Color(0xFF10B981)),
                    _heroBadge(Icons.vpn_key_outlined, profile.is2faEnabled ? '2FA Active' : '2FA Off', AppColors.primary),
                    _heroBadge(Icons.cloud_done_rounded, 'Cloud Synced', const Color(0xFF38BDF8)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Edit Profile',
                    icon: Icons.edit_rounded,
                    height: 40,
                    onPressed: () => _showEditProfileDialog(context, profile, provider),
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => _pickAndUploadAvatar(context, provider),
                borderRadius: BorderRadius.circular(50),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primarySoft,
                        backgroundImage: profile.avatarUrl.isNotEmpty ? NetworkImage(profile.avatarUrl) : null,
                        onBackgroundImageError: profile.avatarUrl.isNotEmpty ? (exception, stackTrace) {} : null,
                        child: profile.avatarUrl.isEmpty
                            ? Text(
                                profile.name.isNotEmpty ? profile.name.substring(0, 1).toUpperCase() : 'A',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.accentPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Tooltip(
                          message: 'Change Profile Picture',
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'SUPERUSER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF93C5FD),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.role} • ${profile.department}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _heroBadge(Icons.shield_outlined, 'Tier-1 Security', const Color(0xFF10B981)),
                        _heroBadge(Icons.vpn_key_outlined, profile.is2faEnabled ? '2FA Active' : '2FA Off', AppColors.primary),
                        _heroBadge(Icons.cloud_done_rounded, 'Cloud Synced', const Color(0xFF38BDF8)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'Edit Profile',
                icon: Icons.edit_rounded,
                height: 42,
                onPressed: () => _showEditProfileDialog(context, profile, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(
    BuildContext context,
    dynamic profile,
    AdminProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Administrative Credentials',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                tooltip: 'Edit Information',
                onPressed: () => _showEditProfileDialog(context, profile, provider),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          _profileInfoRow('Full Name', profile.name, Icons.person_outline),
          _profileInfoRowWithBadge('Official Email', profile.email, Icons.email_outlined, 'Locked Identifier'),
          _profileInfoRow('Contact Phone', profile.phone.isNotEmpty ? profile.phone : 'Not set', Icons.phone_outlined),
          _profileInfoRowWithRoleBadge('Admin Role', profile.role, Icons.security_rounded),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              profile.bio.isNotEmpty
                  ? profile.bio
                  : 'PennyPal Administrator responsible for system governance, content, and data integrity.',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfoRowWithRoleBadge(String label, String role, IconData icon) {
    final roleText = role.trim().isNotEmpty ? role.trim() : 'Super Administrator';
    final isSuper = roleText.toLowerCase().contains('super');
    final badgeColor = isSuper ? const Color(0xFF1D4ED8) : AppColors.accentPink;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuper ? Icons.verified_rounded : Icons.shield_rounded,
                  size: 13,
                  color: badgeColor,
                ),
                const SizedBox(width: 5),
                Text(
                  roleText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfoRowWithBadge(String label, String value, IconData icon, String badgeText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 10, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(
                  badgeText,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(
    BuildContext context,
    dynamic profile,
    AdminProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
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
          const Row(
            children: [
              Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Security & Authentication',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 6),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text('Admin Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Change password with Firebase Auth credential verification', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            trailing: OutlinedButton(
              onPressed: () => _showChangePasswordDialog(context, provider),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Change'),
            ),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phonelink_lock_rounded, color: Color(0xFF10B981), size: 20),
            ),
            title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Requires SMS or Authenticator code on new device login', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            value: profile.is2faEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: (_) => provider.toggle2fa(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(BuildContext context) {
    final permissions = [
      {'title': 'User Management & Status Control', 'icon': Icons.people_alt_rounded, 'granted': true},
      {'title': 'Educational Content Publisher', 'icon': Icons.menu_book_rounded, 'granted': true},
      {'title': 'Category & Icon Configuration', 'icon': Icons.category_rounded, 'granted': true},
      {'title': 'Audit Reports & Financial Export', 'icon': Icons.analytics_rounded, 'granted': true},
      {'title': 'System Settings & Cloudinary Admin', 'icon': Icons.settings_rounded, 'granted': true},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Administrative Rights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              StatusBadge.active(label: 'Full Authority'),
            ],
          ),
          const Divider(),
          const SizedBox(height: 6),
          ...permissions.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(p['icon'] as IconData, size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p['title'] as String,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
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
          const Row(
            children: [
              Icon(Icons.devices_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Active Session',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 6),
          _profileInfoRow('Current Platform', 'PennyPal Admin Web Console', Icons.laptop_chromebook_rounded),
          _profileInfoRow('Database Channel', 'Cloud Firestore Live', Icons.cloud_done_outlined),
          _profileInfoRow(
            'Session Established',
            DateFormat('hh:mm a, dd MMM yyyy').format(profile.lastLogin),
            Icons.access_time_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
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
          const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text(
                'Terminate Administrative Session',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Logging out ends your secure administrative token and signs you out of Firebase Auth.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _confirmLogout(context, provider),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out of PennyPal Admin',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, AdminProvider provider) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Uploading profile photo to Cloudinary...'),
              ],
            ),
            duration: Duration(seconds: 4),
          ),
        );

        final bytes = await picked.readAsBytes();
        final secureUrl = await provider.uploadAdminAvatar(bytes, picked.name);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (secureUrl != null && secureUrl.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Profile photo updated and saved to Cloud Firestore!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.danger,
              content: Text('Failed to upload image. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Error picking image: $e'),
        ),
      );
    }
  }

  void _showEditProfileDialog(
    BuildContext context,
    dynamic profile,
    AdminProvider provider,
  ) {
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final bioCtrl = TextEditingController(text: profile.bio);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Edit Admin Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: nameCtrl,
                    label: 'Admin Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Admin name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: emailCtrl,
                    label: 'Official Email (Permanent Identifier)',
                    readOnly: true,
                    enabled: false,
                    prefixIcon: Icons.email_outlined,
                    suffixIcon: const Tooltip(
                      message: 'Admin email cannot be changed as it is the primary system identifier.',
                      child: Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Email is locked to preserve administrative access integrity.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: phoneCtrl,
                    label: 'Contact Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    hintText: '+92 300 1234567',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: bioCtrl,
                    label: 'About Admin',
                    prefixIcon: Icons.info_outline_rounded,
                    hintText: 'Describe administrative role, responsibilities, or bio...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          CustomButton(
            text: 'Save Changes',
            icon: Icons.check_circle_rounded,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                provider.updateAdminProfile(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  bio: bioCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('Admin profile updated and synchronized!'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AdminProvider provider) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text('Change Admin Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter your existing password to authenticate, followed by your new password.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: currentPassCtrl,
                      label: 'Current Password',
                      obscureText: obscureCurrent,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Current password is required' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: newPassCtrl,
                      label: 'New Password',
                      obscureText: obscureNew,
                      prefixIcon: Icons.key_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: confirmPassCtrl,
                      label: 'Confirm New Password',
                      obscureText: obscureConfirm,
                      prefixIcon: Icons.check_circle_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      validator: (v) {
                        if (v != newPassCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isSubmitting = true);
                      try {
                        await provider.changeAdminPassword(
                          currentPassword: currentPassCtrl.text.trim(),
                          newPassword: newPassCtrl.text.trim(),
                        );

                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('Password updated successfully in Firebase Auth!'),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.danger,
                            content: Text('Failed to change password: $e'),
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log Out of Admin Portal?'),
        content: const Text('Are you sure you want to end your administrative session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              provider.logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

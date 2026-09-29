import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddUserScreen extends StatefulWidget {
  final UserModel? user;

  const AddUserScreen({super.key, this.user});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String _selectedRole = 'Standard User';
  bool _isBlocked = false;

  final List<String> _roles = [
    'Standard User',
    'Student User',
    'Premium User',
    'Administrator',
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u?.name ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _phoneController = TextEditingController(text: u?.phone ?? '');
    if (u != null) {
      _selectedRole = _roles.contains(u.role) ? u.role : 'Standard User';
      _isBlocked = u.isBlocked;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
      case 'admin':
        return AppColors.accentPink;
      case 'premium user':
      case 'premium':
        return const Color(0xFFF59E0B);
      case 'student user':
      case 'student':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'premium user':
      case 'premium':
        return Icons.workspace_premium_rounded;
      case 'student user':
      case 'student':
        return Icons.school_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<UserController>();
    final isEditing = widget.user != null;
    bool success;
    if (isEditing) {
      success = await controller.updateUser(
        uid: widget.user!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        isBlocked: _isBlocked,
        newAvatarBytes: controller.selectedAvatarBytes,
        newAvatarFileName: controller.avatarFileName,
        existingAvatarUrl: widget.user!.avatarUrl,
      );
    } else {
      success = await controller.createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        isBlocked: _isBlocked,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEditing
                      ? 'User profile updated in database!'
                      : 'User "${_nameController.text.trim()}" provisioned in database!',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final error = controller.errorMessage ??
          'Failed to save user. Please check Firestore rules and connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 650;
    final isEditing = widget.user != null;
    final roleColor = _getRoleColor(_selectedRole);
    final roleIcon = _getRoleIcon(_selectedRole);

    final hasPickedAvatar = controller.selectedAvatarBytes != null;
    final hasExistingAvatar = widget.user?.avatarUrl.isNotEmpty == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User Profile' : 'Provision New User'),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 20 : 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            roleColor.withValues(alpha: 0.08),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: roleColor.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: hasPickedAvatar
                                  ? Image.memory(
                                      controller.selectedAvatarBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : (hasExistingAvatar
                                      ? Image.network(
                                          widget.user!.avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              _buildInitialsAvatar(roleColor),
                                        )
                                      : _buildInitialsAvatar(roleColor)),
                            ),
                          ),
                          const SizedBox(width: 18),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: roleColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(roleIcon, size: 12, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            _selectedRole.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isBlocked
                                            ? AppColors.danger.withValues(alpha: 0.1)
                                            : AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _isBlocked
                                              ? AppColors.danger.withValues(alpha: 0.3)
                                              : AppColors.success.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _isBlocked
                                                  ? AppColors.danger
                                                  : AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isBlocked ? 'BLOCKED' : 'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: _isBlocked
                                                  ? AppColors.danger
                                                  : AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _nameController.text.trim().isEmpty
                                      ? 'Full Name Preview'
                                      : _nameController.text.trim(),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: _nameController.text.trim().isEmpty
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _emailController.text.trim().isEmpty
                                      ? 'user@pennypal.app'
                                      : _emailController.text.trim(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Text(
                          'User Profile Photo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (hasPickedAvatar) ...[
                          TextButton.icon(
                            onPressed: () => controller.pickAvatar(),
                            icon: const Icon(Icons.refresh_rounded, size: 15),
                            label: const Text('Change Photo'),
                          ),
                          TextButton.icon(
                            onPressed: () => controller.clearAvatar(),
                            icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.danger),
                            label: const Text('Remove', style: TextStyle(color: AppColors.danger)),
                          ),
                        ] else
                          TextButton.icon(
                            onPressed: () => controller.pickAvatar(),
                            icon: const Icon(Icons.add_a_photo_rounded, size: 15),
                            label: const Text('Upload Photo'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hintText: 'e.g. Sarah Jenkins',
                      prefixIcon: Icons.person_outline_rounded,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter user full name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hintText: 'e.g. sarah.j@pennypal.app',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter user email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    LayoutBuilder(
                      builder: (context, fieldConstraints) {
                        final isStacked = fieldConstraints.maxWidth < 450;
                        final phoneField = CustomTextField(
                          controller: _phoneController,
                          label: 'Phone Number (Optional)',
                          hintText: 'e.g. +1 555 123 4567',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                        );

                        final roleField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Role',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: roleColor, width: 1.8),
                                ),
                              ),
                              items: _roles.map((r) {
                                final col = _getRoleColor(r);
                                final ic = _getRoleIcon(r);
                                return DropdownMenuItem<String>(
                                  value: r,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(ic, size: 16, color: col),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          r,
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedRole = val);
                                }
                              },
                            ),
                          ],
                        );

                        if (isStacked) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              phoneField,
                              const SizedBox(height: 18),
                              roleField,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: phoneField),
                            const SizedBox(width: 14),
                            Expanded(child: roleField),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isBlocked
                                  ? AppColors.danger.withValues(alpha: 0.12)
                                  : AppColors.success.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isBlocked ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                              color: _isBlocked ? AppColors.danger : AppColors.success,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isBlocked ? 'Account Blocked (Suspended)' : 'Account Active (Permitted)',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isBlocked
                                      ? 'User cannot log in or record transactions on the mobile app'
                                      : 'User is authorized to sync data, track expenses, and access guides',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: !_isBlocked,
                            activeThumbColor: AppColors.success,
                            onChanged: (val) => setState(() => _isBlocked = !val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    CustomButton(
                      text: isEditing ? 'Save Changes to Database' : 'Provision User to Database',
                      icon: Icons.cloud_upload_rounded,
                      isLoading: controller.isLoading,
                      onPressed: controller.isLoading ? null : _submitForm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(Color roleColor) {
    final initials = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim().substring(0, 1).toUpperCase()
        : 'U';
    return Container(
      color: roleColor.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: roleColor,
          ),
        ),
      ),
    );
  }
}

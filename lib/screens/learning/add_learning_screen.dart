import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/learning_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/learning_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddLearningScreen extends StatefulWidget {
  final LearningContentModel? article;

  const AddLearningScreen({super.key, this.article});

  @override
  State<AddLearningScreen> createState() => _AddLearningScreenState();
}

class _AddLearningScreenState extends State<AddLearningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _contentController;
  late final TextEditingController _durationController;

  String _selectedCategory = 'Budgeting';
  String _selectedLevel = 'Beginner';
  bool _isFeatured = false;

  final List<String> _categories = [
    'Basics',
    'Budgeting',
    'Saving',
    'Goals',
    'Investing',
  ];

  final List<String> _levels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.article;
    _titleController = TextEditingController(text: a?.title ?? '');
    _descController = TextEditingController(text: a?.description ?? '');
    _contentController = TextEditingController(text: a?.content ?? '');
    _durationController = TextEditingController(
      text: a != null ? a.durationMinutes.toString() : '5',
    );
    if (a != null) {
      _selectedCategory = a.category;
      _selectedLevel = a.level;
      _isFeatured = a.isFeatured;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'basics':
        return const Color(0xFF2563EB);
      case 'budgeting':
        return AppColors.accentPink;
      case 'saving':
        return AppColors.success;
      case 'goals':
        return const Color(0xFFF59E0B);
      case 'investing':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<LearningController>();
    final isEditing = widget.article != null;

    final duration = int.tryParse(_durationController.text.trim()) ?? 5;

    bool success;
    if (isEditing) {
      success = await controller.updateLearningArticle(
        id: widget.article!.id,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        level: _selectedLevel,
        durationMinutes: duration,
        description: _descController.text.trim(),
        content: _contentController.text.trim(),
        isFeatured: _isFeatured,
        newImageBytes: controller.selectedImageBytes,
        newImageFileName: controller.imageFileName,
        existingImageUrl: widget.article!.imageUrl,
      );
    } else {
      if (controller.selectedImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Please upload a banner image for the article.'),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      success = await controller.createLearningArticle(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        level: _selectedLevel,
        durationMinutes: duration,
        description: _descController.text.trim(),
        content: _contentController.text.trim(),
        isFeatured: _isFeatured,
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
                      ? 'Article "${_titleController.text.trim()}" updated successfully!'
                      : 'Article "${_titleController.text.trim()}" published to Firebase!',
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
          'Failed to save article. Please verify Firestore rules and connection.';
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
    final controller = context.watch<LearningController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 650;
    final isEditing = widget.article != null;
    final themeColor = _getCategoryColor(_selectedCategory);

    final hasPickedBytes = controller.selectedImageBytes != null;
    final hasExistingUrl = widget.article?.imageUrl.isNotEmpty == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Learning Article' : 'Add Learning Content'),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_rounded, color: themeColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                isEditing ? 'EDITING ARTICLE' : 'NEW FINANCIAL GUIDE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: SizedBox(
                              height: 160,
                              width: double.infinity,
                              child: hasPickedBytes
                                  ? Image.memory(
                                      controller.selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : (hasExistingUrl
                                      ? Image.network(
                                          widget.article!.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderBanner(themeColor),
                                        )
                                      : _buildPlaceholderBanner(themeColor)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: themeColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _selectedCategory.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        _selectedLevel,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_durationController.text.trim().isEmpty ? '5' : _durationController.text.trim()} min read',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _titleController.text.trim().isEmpty
                                      ? 'Article Title Preview'
                                      : _titleController.text.trim(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _titleController.text.trim().isEmpty
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _descController.text.trim().isEmpty
                                      ? 'Your short summary preview will appear here as you type...'
                                      : _descController.text.trim(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 24),

                    const Text(
                      'Article Banner Image',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: controller.isLoading ? null : () => controller.pickImage(),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: (hasPickedBytes || hasExistingUrl)
                                ? themeColor.withValues(alpha: 0.5)
                                : AppColors.border,
                            width: (hasPickedBytes || hasExistingUrl) ? 1.5 : 1,
                          ),
                        ),
                        child: hasPickedBytes
                            ? Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      controller.selectedImageBytes!,
                                      width: 90,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 16,
                                              color: AppColors.success,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                controller.imageFileName ?? 'Selected Image',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Ready to upload to Cloudinary CDN',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => controller.pickImage(),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Change'),
                                  ),
                                  IconButton(
                                    onPressed: () => controller.clearImage(),
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    color: AppColors.danger,
                                    tooltip: 'Remove',
                                  ),
                                ],
                              )
                            : (hasExistingUrl
                                ? Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          widget.article!.imageUrl,
                                          width: 90,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderBanner(themeColor),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current Article Banner',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Click to replace with a new image from device',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => controller.pickImage(),
                                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                                        label: const Text('Replace'),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: themeColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 26,
                                          color: themeColor,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Select Article Banner Image',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Click to upload JPG, PNG, or WEBP (Direct Cloudinary upload)',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )),
                      ),
                    ),

                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: _titleController,
                      label: 'Article Title',
                      hintText: 'e.g. 5 Habits of Financially Healthy Students',
                      prefixIcon: Icons.edit_note_rounded,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an article title';
                        }
                        if (value.trim().length < 4) {
                          return 'Title must be at least 4 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCategory,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
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
                                    borderSide: BorderSide(color: themeColor, width: 1.8),
                                  ),
                                ),
                                items: _categories.map((c) {
                                  final col = _getCategoryColor(c);
                                  return DropdownMenuItem<String>(
                                    value: c,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: col,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(c, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCategory = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Difficulty Level',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedLevel,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
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
                                    borderSide: BorderSide(color: themeColor, width: 1.8),
                                  ),
                                ),
                                items: _levels.map((l) {
                                  return DropdownMenuItem<String>(
                                    value: l,
                                    child: Text(l, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedLevel = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    CustomTextField(
                      controller: _durationController,
                      label: 'Read Duration (minutes)',
                      hintText: 'e.g. 5',
                      prefixIcon: Icons.schedule_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter read duration';
                        }
                        final numVal = int.tryParse(value.trim());
                        if (numVal == null || numVal <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    CustomTextField(
                      controller: _descController,
                      label: 'Short Summary (Card Excerpt)',
                      hintText: 'A concise 1-2 sentence overview shown to users on learning cards...',
                      prefixIcon: Icons.short_text_rounded,
                      maxLines: 2,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a short summary';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    CustomTextField(
                      controller: _contentController,
                      label: 'Detailed Learning Content',
                      hintText: 'Write the complete financial lesson, key takeaways, and action steps...',
                      prefixIcon: Icons.menu_book_rounded,
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide article content';
                        }
                        if (value.trim().length < 20) {
                          return 'Content should be at least 20 characters';
                        }
                        return null;
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
                              color: _isFeatured
                                  ? const Color(0xFFFEF3C7)
                                  : AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              color: _isFeatured ? const Color(0xFFD97706) : AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Feature this Article',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Presents this guide as a prominent hero card on the mobile app home screen',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isFeatured,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isFeatured = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    CustomButton(
                      text: isEditing
                          ? 'Save Changes to Firebase'
                          : 'Publish Article to Firebase',
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

  Widget _buildPlaceholderBanner(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.withValues(alpha: 0.15),
            themeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 38,
              color: themeColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Text(
              'No Banner Selected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: themeColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

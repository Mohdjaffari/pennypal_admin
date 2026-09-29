import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/faq_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/faq_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddFaqScreen extends StatefulWidget {
  final FaqModel? faq;

  const AddFaqScreen({super.key, this.faq});

  @override
  State<AddFaqScreen> createState() => _AddFaqScreenState();
}

class _AddFaqScreenState extends State<AddFaqScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final TextEditingController _orderController;

  String _selectedCategory = 'Expenses';
  bool _isActive = true;
  bool _isPreviewExpanded = true;

  final List<String> _categories = [
    'Expenses',
    'Security',
    'Budgeting',
    'Goals',
    'Reports',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.faq;
    _questionController = TextEditingController(text: f?.question ?? '');
    _answerController = TextEditingController(text: f?.answer ?? '');
    _orderController = TextEditingController(
      text: f != null ? f.displayOrder.toString() : '1',
    );
    if (f != null) {
      _selectedCategory = f.category;
      _isActive = f.isActive;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'expenses':
        return AppColors.accentPink;
      case 'security':
        return const Color(0xFFF59E0B);
      case 'budgeting':
        return const Color(0xFF2563EB);
      case 'goals':
        return AppColors.success;
      case 'reports':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'expenses':
        return Icons.receipt_long_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'budgeting':
        return Icons.pie_chart_rounded;
      case 'goals':
        return Icons.flag_rounded;
      case 'reports':
        return Icons.bar_chart_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<FaqController>();
    final isEditing = widget.faq != null;
    final order = int.tryParse(_orderController.text.trim()) ?? 1;

    bool success;
    if (isEditing) {
      success = await controller.updateFaq(
        id: widget.faq!.id,
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        category: _selectedCategory,
        isActive: _isActive,
        displayOrder: order,
      );
    } else {
      success = await controller.createFaq(
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        category: _selectedCategory,
        isActive: _isActive,
        displayOrder: order,
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
                      ? 'FAQ updated successfully!'
                      : 'FAQ published to Firebase successfully!',
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
          'Failed to save FAQ. Please verify Firestore rules and connection.';
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
    final controller = context.watch<FaqController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 650;
    final isEditing = widget.faq != null;
    final themeColor = _getCategoryColor(_selectedCategory);
    final categoryIcon = _getCategoryIcon(_selectedCategory);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit FAQ Item' : 'Add FAQ Question'),
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
                              Icon(categoryIcon, color: themeColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                isEditing ? 'EDITING FAQ' : 'NEW HELP ITEM',
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isActive
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.textMuted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isActive
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isActive ? AppColors.success : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isActive ? 'LIVE IN APP' : 'DRAFT (HIDDEN)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _isActive ? AppColors.success : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  categoryIcon,
                                  color: themeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: themeColor,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _selectedCategory.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'PREVIEW',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _questionController.text.trim().isEmpty
                                          ? 'Question Preview will appear here...'
                                      : _questionController.text.trim(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _questionController.text.trim().isEmpty
                                            ? AppColors.textMuted
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isPreviewExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: themeColor,
                                ),
                                tooltip: _isPreviewExpanded ? 'Collapse Answer' : 'Expand Answer',
                                onPressed: () {
                                  setState(() {
                                    _isPreviewExpanded = !_isPreviewExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_isPreviewExpanded) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Text(
                              _answerController.text.trim().isEmpty
                                  ? 'Your comprehensive answer preview will appear here as you type in the editor below...'
                                  : _answerController.text.trim(),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: _answerController.text.trim().isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: _questionController,
                      label: 'Question',
                      hintText: 'e.g. How do I link multiple bank cards to my PennyPal budget?',
                      prefixIcon: Icons.help_outline_rounded,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a question';
                        }
                        if (value.trim().length < 5) {
                          return 'Question must be at least 5 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FAQ Category',
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
                                  final icon = _getCategoryIcon(c);
                                  return DropdownMenuItem<String>(
                                    value: c,
                                    child: Row(
                                      children: [
                                        Icon(icon, size: 16, color: col),
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
                          child: CustomTextField(
                            controller: _orderController,
                            label: 'Display Order',
                            hintText: '1',
                            prefixIcon: Icons.format_list_numbered_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    CustomTextField(
                      controller: _answerController,
                      label: 'Comprehensive Answer',
                      hintText: 'Provide clear, step-by-step instructions or explanations for mobile users...',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide an answer';
                        }
                        if (value.trim().length < 10) {
                          return 'Answer must be at least 10 characters';
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
                              color: _isActive
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.visibility_rounded,
                              color: _isActive ? AppColors.success : AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Publish Immediately (Active)',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'When active, this FAQ is instantly visible to PennyPal mobile users',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    CustomButton(
                      text: isEditing ? 'Save Changes to Firebase' : 'Publish FAQ to Firebase',
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
}

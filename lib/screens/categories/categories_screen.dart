import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/category_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/category_icons.dart';
import '../../models/category_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import 'add_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    final categoryCtrl = context.watch<CategoryController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 400;
              return Container(
                padding: EdgeInsets.all(isSmall ? 10 : 16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                  Text(
                                    'User-Side Categories',
                                    style: TextStyle(
                                      fontSize: isSmall ? 15 : 17,
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
                                'Manage global categories synced with PennyPal mobile app & Cloudinary',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomButton(
                          text: isSmall ? 'Add' : 'Add Category',
                          icon: Icons.add_circle_rounded,
                          height: 42,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddCategoryScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _typeTab('all', 'All Categories'),
                          const SizedBox(width: 8),
                          _typeTab('expense', 'Expense'),
                          const SizedBox(width: 8),
                          _typeTab('income', 'Income'),
                          const SizedBox(width: 8),
                          _typeTab('learning', 'Learning'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: categoryCtrl.getCategoriesStream(selectedType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final docs = snapshot.data!.docs;
                  final categories = docs.map((doc) {
                    return CategoryModel.fromMap(doc.data(), docId: doc.id);
                  }).toList();

                  return _buildGridView(context, categories, categoryCtrl);
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 56,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No categories found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Click "Add Category" above to publish your first category to Firebase.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeTab(String type, String label) {
    final isSelected = selectedType == type;
    return InkWell(
      onTap: () => setState(() => selectedType = type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<CategoryModel> categories,
    CategoryController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double mainAxisExtent;
        if (screenWidth >= 1200) {
          crossAxisCount = 3;
          mainAxisExtent = 148;
        } else if (screenWidth >= 700) {
          crossAxisCount = 2;
          mainAxisExtent = 148;
        } else {
          crossAxisCount = 1;
          mainAxisExtent = 154;
        }

        return GridView.builder(
          padding: EdgeInsets.all(screenWidth < 400 ? 10 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: mainAxisExtent,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _buildCategoryCard(context, cat, controller);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryModel cat,
    CategoryController controller,
  ) {
    final bool hasCloudinaryIcon =
        cat.icon != null && cat.icon!.startsWith('http');
    final IconData iconData = CategoryIcons.getIconData(
      cat.iconName.isNotEmpty ? cat.iconName : cat.icon,
    );

    Color typeColor = AppColors.primary;
    if (cat.type == 'expense') typeColor = AppColors.accentPink;
    if (cat.type == 'income') typeColor = AppColors.success;
    if (cat.type == 'learning') typeColor = const Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: typeColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: hasCloudinaryIcon
                  ? Image.network(
                      cat.icon!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          iconData,
                          color: typeColor,
                          size: 26,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        iconData,
                        color: typeColor,
                        size: 26,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cat.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cat.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Created by ${cat.createdBy ?? 'admin'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  cat.id != null ? 'ID: ${cat.id}' : 'Synced with Firestore',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditCategoryDialog(context, cat, controller);
              } else if (value == 'delete') {
                _confirmDeleteCategory(context, cat, controller);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Edit Category'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Delete Category', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    CategoryModel cat,
    CategoryController controller,
  ) {
    final nameCtrl = TextEditingController(text: cat.name);
    String selectedType = cat.type;
    String selectedIconKey = cat.iconName.isNotEmpty
        ? cat.iconName
        : (cat.icon != null && !cat.icon!.startsWith('http')
            ? cat.icon!
            : 'fastfood_rounded');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Color typeColor = AppColors.primary;
          if (selectedType.toLowerCase() == 'expense') typeColor = AppColors.accentPink;
          if (selectedType.toLowerCase() == 'income') typeColor = AppColors.success;
          if (selectedType.toLowerCase() == 'learning') typeColor = const Color(0xFF8B5CF6);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Category'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: nameCtrl,
                      label: 'Category Name',
                      hintText: 'e.g. Health & Fitness',
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Category Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: ['expense', 'income', 'learning'].contains(selectedType.toLowerCase())
                          ? selectedType.toLowerCase()
                          : 'expense',
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                        DropdownMenuItem(value: 'income', child: Text('Income')),
                        DropdownMenuItem(value: 'learning', child: Text('Learning')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category Icon',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 130,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: GridView.builder(
                        itemCount: CategoryIcons.allIcons.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                        itemBuilder: (context, idx) {
                          final item = CategoryIcons.allIcons[idx];
                          final isSelected = selectedIconKey == item.key;
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedIconKey = item.key;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? typeColor.withValues(alpha: 0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? typeColor
                                      : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                size: 20,
                                color: isSelected ? typeColor : AppColors.textPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (cat.id != null) {
                    await controller.updateCategory(
                      cat.id!,
                      name: nameCtrl.text.trim(),
                      type: selectedType,
                      iconName: selectedIconKey,
                    );
                  }
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    CategoryModel cat,
    CategoryController controller,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${cat.name}" from Firebase? This will remove it for all mobile users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (cat.id != null) {
                final success = await controller.deleteCategory(cat.id!);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category deleted successfully from Firebase'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

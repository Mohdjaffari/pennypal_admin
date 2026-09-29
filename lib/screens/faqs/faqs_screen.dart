import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/faq_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/faq_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'add_faq_screen.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Expenses',
    'Security',
    'Budgeting',
    'Goals',
    'Reports',
    'General',
  ];

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

  @override
  Widget build(BuildContext context) {
    final faqCtrl = context.watch<FaqController>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                                'Help Center & FAQs Manager',
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
                            'Manage self-service help questions and troubleshooting guides for PennyPal mobile users',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'Add FAQ',
                      icon: Icons.add_circle_outline_rounded,
                      height: 42,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddFaqScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _categoryTab(cat),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: faqCtrl.getFaqsStream(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final docs = snapshot.data!.docs;
                  final faqs = docs.map((doc) {
                    return FaqModel.fromMap(doc.data(), docId: doc.id);
                  }).toList();

                  faqs.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

                  return _buildFaqList(context, faqs, faqCtrl, adminProvider);
                }

                return EmptyStateWidget(
                  icon: Icons.quiz_outlined,
                  title: 'No FAQs Found',
                  subtitle: 'Add common questions and answers for PennyPal app users.',
                  buttonText: 'Add New FAQ',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddFaqScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTab(String category) {
    final isSelected = _selectedCategory.toLowerCase() == category.toLowerCase();
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFaqList(
    BuildContext context,
    List<FaqModel> faqs,
    FaqController faqCtrl,
    AdminProvider adminProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return _buildFaqCard(context, faq, faqCtrl, adminProvider);
      },
    );
  }

  Widget _buildFaqCard(
    BuildContext context,
    FaqModel faq,
    FaqController faqCtrl,
    AdminProvider adminProvider,
  ) {
    final catColor = _getCategoryColor(faq.category);
    final catIcon = _getCategoryIcon(faq.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(catIcon, color: catColor, size: 20),
          ),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    faq.category,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: catColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: faq.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    faq.isActive ? 'ACTIVE' : 'DRAFT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: faq.isActive ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    faq.answer,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: faq.isActive,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) async {
                              await faqCtrl.toggleFaqActive(faq.id, faq.isActive);
                              adminProvider.toggleFaqActive(faq.id);
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            faq.isActive ? 'Visible in Mobile App' : 'Hidden from Users',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: faq.isActive ? AppColors.success : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: AppColors.primary,
                            tooltip: 'Edit FAQ',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddFaqScreen(faq: faq),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            color: AppColors.danger,
                            tooltip: 'Delete FAQ',
                            onPressed: () => _confirmDeleteFaq(
                              context,
                              faqCtrl,
                              adminProvider,
                              faq,
                            ),
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

  void _confirmDeleteFaq(
    BuildContext context,
    FaqController faqCtrl,
    AdminProvider adminProvider,
    FaqModel faq,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete FAQ?'),
        content: Text('Are you sure you want to delete "${faq.question}" from Firebase?'),
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
              final success = await faqCtrl.deleteFaq(faq.id);
              adminProvider.deleteFaq(faq.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    content: Text(
                      success
                          ? 'FAQ removed from Firebase.'
                          : 'Failed to delete FAQ. Check permissions.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

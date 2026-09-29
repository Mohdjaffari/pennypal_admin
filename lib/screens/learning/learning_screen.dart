import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/learning_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/learning_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'add_learning_screen.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isGridView = true;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'All',
    'Basics',
    'Budgeting',
    'Saving',
    'Goals',
    'Investing',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final learningCtrl = context.watch<LearningController>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 400;
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 12 : 20,
                  vertical: isSmall ? 10 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text(
                                    isSmall ? 'Learning Manager' : 'Financial Learning Manager',
                                    style: TextStyle(
                                      fontSize: isSmall ? 15 : 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  StatusBadge.active(
                                    label: 'Live Firestore',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Publish financial literacy articles and guides synced with PennyPal mobile app',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomButton(
                          text: isSmall ? 'Add' : 'Add Article',
                          icon: Icons.post_add_rounded,
                          height: 40,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddLearningScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              decoration: InputDecoration(
                                hintText: isSmall
                                    ? 'Search articles...'
                                    : 'Search articles by title or keyword...',
                                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        ),
                        const SizedBox(width: 12),

                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Grid View (Multi-Card)',
                                child: InkWell(
                                  onTap: () => setState(() => _isGridView = true),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _isGridView ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: _isGridView
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      size: 18,
                                      color: _isGridView ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'List View (Single Column)',
                                child: InkWell(
                                  onTap: () => setState(() => _isGridView = false),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: !_isGridView ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: !_isGridView
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      Icons.view_agenda_rounded,
                                      size: 18,
                                      color: !_isGridView ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

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
              );
            },
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: learningCtrl.getLearningStream(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load learning content',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry Connection'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final docs = snapshot.data!.docs;
                  final List<LearningContentModel> loadedArticles = [];

                  for (final doc in docs) {
                    try {
                      loadedArticles.add(LearningContentModel.fromMap(doc.data(), docId: doc.id));
                    } catch (e) {
                      debugPrint("LearningScreen: Skipped doc ${doc.id} due to parse error: $e");
                    }
                  }

                  // Dynamically collect custom categories found in Firestore
                  for (final item in loadedArticles) {
                    final catTrimmed = item.category.trim();
                    if (catTrimmed.isNotEmpty &&
                        !_categories.any((c) => c.toLowerCase() == catTrimmed.toLowerCase())) {
                      _categories.add(catTrimmed);
                    }
                  }

                  var articles = List<LearningContentModel>.from(loadedArticles);

                  // Case-insensitive category filtering
                  if (_selectedCategory.toLowerCase() != 'all') {
                    articles = articles.where((a) {
                      return a.category.trim().toLowerCase() == _selectedCategory.toLowerCase();
                    }).toList();
                  }

                  // Search filtering across title, description, and category
                  if (_searchQuery.isNotEmpty) {
                    articles = articles.where((a) {
                      return a.title.toLowerCase().contains(_searchQuery) ||
                          a.description.toLowerCase().contains(_searchQuery) ||
                          a.category.toLowerCase().contains(_searchQuery) ||
                          a.content.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (articles.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No articles match "$_searchQuery"'
                                  : 'No articles in "$_selectedCategory"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try searching for another financial term or reset your search query.'
                                  : 'Switch to "All" or add a new guide to this category.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = 'All';
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Show All Articles'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return _buildResponsiveArticlesContent(
                    context,
                    articles,
                    learningCtrl,
                    adminProvider,
                  );
                }

                return EmptyStateWidget(
                  icon: Icons.menu_book_rounded,
                  title: 'No Learning Articles Found',
                  subtitle: 'Add educational guides to help PennyPal users manage money better.',
                  buttonText: 'Add New Article',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddLearningScreen(),
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
    final catColor = _getCategoryColor(category);

    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != 'All') ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : catColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveArticlesContent(
    BuildContext context,
    List<LearningContentModel> articles,
    LearningController learningCtrl,
    AdminProvider adminProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        int crossAxisCount;
        if (screenWidth >= 1350) {
          crossAxisCount = 3;
        } else if (screenWidth >= 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        if (!_isGridView || crossAxisCount == 1) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildLearningCard(context, article, learningCtrl, adminProvider),
              );
            },
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 420,
          ),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return _buildLearningCard(context, article, learningCtrl, adminProvider);
          },
        );
      },
    );
  }

  Widget _buildLearningCard(
    BuildContext context,
    LearningContentModel article,
    LearningController learningCtrl,
    AdminProvider adminProvider,
  ) {
    final catColor = _getCategoryColor(article.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: (article.imageUrl.trim().isNotEmpty &&
                        (article.imageUrl.startsWith('http://') || article.imageUrl.startsWith('https://')))
                    ? Image.network(
                        article.imageUrl,
                        height: 175,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 175,
                          color: catColor.withValues(alpha: 0.08),
                          child: Center(
                            child: Icon(Icons.menu_book_rounded, size: 48, color: catColor),
                          ),
                        ),
                      )
                    : Container(
                        height: 175,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              catColor.withValues(alpha: 0.15),
                              catColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_rounded, size: 48, color: catColor),
                              const SizedBox(height: 6),
                              Text(
                                article.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: catColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        article.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () async {
                    await learningCtrl.toggleFeatured(article.id, article.isFeatured);
                    adminProvider.toggleFeaturedLearning(article.id);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: article.isFeatured
                          ? AppColors.accentPink
                          : Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          article.isFeatured ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.isFeatured ? 'Featured' : 'Standard',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${article.durationMinutes} min',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.level,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: catColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.visibility_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readCount} reads',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    article.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),

                  const Spacer(),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(article.publishedDate),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                            color: AppColors.textSecondary,
                            tooltip: 'Read Full Content',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showArticlePreviewDialog(context, article),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: AppColors.primary,
                            tooltip: 'Edit Article',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddLearningScreen(article: article),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: AppColors.danger,
                            tooltip: 'Delete Article',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDeleteArticle(
                              context,
                              learningCtrl,
                              adminProvider,
                              article,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showArticlePreviewDialog(BuildContext context, LearningContentModel article) {
    final catColor = _getCategoryColor(article.category);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: (article.imageUrl.trim().isNotEmpty &&
                          (article.imageUrl.startsWith('http://') || article.imageUrl.startsWith('https://')))
                      ? Image.network(
                          article.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 220,
                            color: catColor.withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(Icons.menu_book_rounded, size: 54, color: catColor),
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          color: catColor.withValues(alpha: 0.1),
                          child: Center(
                            child: Icon(Icons.menu_book_rounded, size: 54, color: catColor),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${article.durationMinutes} min read • ${article.level}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        article.title,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        article.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        article.content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteArticle(
    BuildContext context,
    LearningController learningCtrl,
    AdminProvider adminProvider,
    LearningContentModel article,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Article?'),
        content: Text('Are you sure you want to delete "${article.title}"? This will remove it from Firebase permanently.'),
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
              final success = await learningCtrl.deleteLearningArticle(article.id);
              adminProvider.deleteLearningContent(article.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    content: Text(
                      success
                          ? 'Article deleted from Firebase.'
                          : 'Failed to delete article. Check permissions.',
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/feedback_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/status_badge.dart';

class FeedbacksScreen extends StatefulWidget {
  const FeedbacksScreen({super.key});

  @override
  State<FeedbacksScreen> createState() => _FeedbacksScreenState();
}

class _FeedbacksScreenState extends State<FeedbacksScreen> {
  String _selectedCategory = 'All'; // All, App Experience, Feature Request, Bug Report, General
  int? _selectedStarRating; // null = all, 1, 2, 3, 4, 5
  String _selectedReviewStatus = 'All'; // All, Pending, Reviewed
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().refreshFeedbacks();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(AdminProvider provider) async {
    setState(() => _isRefreshing = true);
    await provider.refreshFeedbacks();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    final filteredFeedbacks = provider.feedbacks.where((f) {
      if (_selectedCategory != 'All' &&
          f.feedbackType.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      if (_selectedStarRating != null && f.rating != _selectedStarRating) {
        return false;
      }

      if (_selectedReviewStatus == 'Pending' && f.isReviewed) return false;
      if (_selectedReviewStatus == 'Reviewed' && !f.isReviewed) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchesUser = f.userName.toLowerCase().contains(query);
        final matchesEmail = f.userEmail.toLowerCase().contains(query);
        final matchesComment = f.comments.toLowerCase().contains(query);
        final matchesCategory = f.feedbackType.toLowerCase().contains(query);
        if (!matchesUser && !matchesEmail && !matchesComment && !matchesCategory) {
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
          _buildRatingAnalyticsBanner(context, provider),
          _buildFilterToolbar(context, provider),
          Expanded(
            child: provider.isFeedbackLoading && provider.feedbacks.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredFeedbacks.isEmpty
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
                          itemCount: filteredFeedbacks.length,
                          itemBuilder: (context, index) {
                            final item = filteredFeedbacks[index];
                            return _buildFeedbackCard(context, item, provider);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingAnalyticsBanner(BuildContext context, AdminProvider provider) {
    final avg = provider.averageFeedbackRating;
    final total = provider.feedbacks.length;
    final pending = provider.pendingFeedbacksCount;
    final fiveStarCount = provider.feedbackStarCounts[5] ?? 0;
    final positiveCount = (provider.feedbackStarCounts[5] ?? 0) + (provider.feedbackStarCounts[4] ?? 0);
    final positivePct = total > 0 ? ((positiveCount / total) * 100).toStringAsFixed(0) : '0';
    final starPercentages = provider.feedbackStarPercentages;
    final starCounts = provider.feedbackStarCounts;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isCompact = outerConstraints.maxWidth < 400;
        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Title & Live Status
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
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'User Feedback & App Reviews',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Direct Firestore sync • User satisfaction analytics & sentiment',
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

          // Rating Breakdown Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Score Block
                        _buildScoreBlock(avg, total),
                        const SizedBox(width: 24),
                        // Middle Star Distribution Bars
                        Expanded(child: _buildStarDistribution(starCounts, starPercentages, total)),
                        const SizedBox(width: 24),
                        // Right Insight Tiles
                        _buildInsightTiles(total, pending, fiveStarCount, positivePct),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildScoreBlock(avg, total),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInsightTiles(total, pending, fiveStarCount, positivePct)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStarDistribution(starCounts, starPercentages, total),
                      ],
                    );
            },
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildScoreBlock(double avg, int total) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: AppColors.pinkGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPink.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            avg.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starVal = index + 1;
              if (avg >= starVal) {
                return const Icon(Icons.star_rounded, size: 14, color: Colors.white);
              } else if (avg >= starVal - 0.5) {
                return const Icon(Icons.star_half_rounded, size: 14, color: Colors.white);
              } else {
                return const Icon(Icons.star_outline_rounded, size: 14, color: Colors.white60);
              }
            }),
          ),
          const SizedBox(height: 6),
          Text(
            '$total reviews',
            style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStarDistribution(Map<int, int> counts, Map<int, double> pcts, int total) {
    return Column(
      children: [5, 4, 3, 2, 1].map((stars) {
        final count = counts[stars] ?? 0;
        final pct = (pcts[stars] ?? 0) / 100.0;
        final isSelected = _selectedStarRating == stars;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedStarRating = isSelected ? null : stars;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '$stars★',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? const Color(0xFFD97706) : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSelected
                            ? const Color(0xFFD97706)
                            : (stars >= 4
                                ? const Color(0xFF10B981)
                                : (stars == 3 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightTiles(int total, int pending, int fiveStars, String positivePct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniTile(
                label: 'Pending Review',
                value: '$pending',
                color: pending > 0 ? AppColors.warning : AppColors.success,
                icon: Icons.pending_actions_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniTile(
                label: '5-Star Ratings',
                value: '$fiveStars',
                color: const Color(0xFF10B981),
                icon: Icons.favorite_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMiniTile(
                label: 'Positive Sentiment',
                value: '$positivePct%',
                color: AppColors.primary,
                icon: Icons.sentiment_satisfied_alt_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniTile(
                label: 'Total Received',
                value: '$total',
                color: AppColors.purple,
                icon: Icons.rate_review_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(BuildContext context, AdminProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 400;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 20,
            vertical: isSmall ? 8 : 12,
          ),
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
                          hintText: isSmall
                              ? 'Search reviews...'
                              : 'Search reviews by user name, email, or comment keywords...',
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
                  if (!isSmall) ...[
                    const SizedBox(width: 12),
                    if (provider.feedbacks.isEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final seeded = await provider.seedSampleFeedbacks();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('Populated $seeded realistic customer reviews into Firestore!'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                        label: const Text('Seed Sample Reviews'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Filter Row: Categories + Status
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryTab('All'),
                    const SizedBox(width: 8),
                    _buildCategoryTab('App Experience'),
                    const SizedBox(width: 8),
                    _buildCategoryTab('Feature Request'),
                    const SizedBox(width: 8),
                    _buildCategoryTab('Bug Report'),
                    const SizedBox(width: 8),
                    _buildCategoryTab('General'),
                    const SizedBox(width: 16),
                    Container(height: 18, width: 1, color: AppColors.border),
                    const SizedBox(width: 16),
                    // Review Status Filter
                    _buildStatusChip('All', _selectedReviewStatus == 'All'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Pending', _selectedReviewStatus == 'Pending'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Reviewed', _selectedReviewStatus == 'Reviewed'),
                    if (_selectedStarRating != null) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => setState(() => _selectedStarRating = null),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD97706)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$_selectedStarRating Stars Only',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.close_rounded, size: 14, color: Color(0xFFD97706)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryTab(String category) {
    final isSelected = _selectedCategory.toLowerCase() == category.toLowerCase();
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedReviewStatus = status),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.border),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, FeedbackModel item, AdminProvider provider) {
    Color getCategoryColor() {
      switch (item.feedbackType.toLowerCase()) {
        case 'bug report':
          return AppColors.danger;
        case 'feature request':
          return AppColors.purple;
        case 'app experience':
          return const Color(0xFF10B981);
        default:
          return AppColors.primary;
      }
    }

    IconData getCategoryIcon() {
      switch (item.feedbackType.toLowerCase()) {
        case 'bug report':
          return Icons.bug_report_outlined;
        case 'feature request':
          return Icons.lightbulb_outline_rounded;
        case 'app experience':
          return Icons.smartphone_rounded;
        default:
          return Icons.chat_bubble_outline_rounded;
      }
    }

    final catColor = getCategoryColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !item.isReviewed ? AppColors.warning.withValues(alpha: 0.35) : AppColors.border,
          width: !item.isReviewed ? 1.5 : 1.0,
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
          // Header: Reviewer Avatar, Name, Email, Reviewed Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: catColor.withValues(alpha: 0.12),
                      child: Text(
                        item.userInitials,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: catColor),
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
                                  item.userName,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Verified User', style: TextStyle(fontSize: 9.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: item.userEmail));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(duration: Duration(seconds: 1), content: Text('User email copied!')),
                              );
                            },
                            child: Text(
                              item.userEmail,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              item.isReviewed
                  ? StatusBadge.custom(
                      label: 'Reviewed',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_outline_rounded,
                    )
                  : StatusBadge.custom(
                      label: 'Needs Review',
                      color: AppColors.warning,
                      icon: Icons.schedule_rounded,
                    ),
            ],
          ),
          const SizedBox(height: 12),

          // Rating Stars & Category Pill
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < item.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 19,
                    color: const Color(0xFFF59E0B),
                  );
                }),
              ),
              const SizedBox(width: 6),
              Text(
                '${item.rating}.0',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 14),
              // Category Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: catColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(getCategoryIcon(), size: 12, color: catColor),
                    const SizedBox(width: 4),
                    Text(
                      item.feedbackType,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Feedback Comments Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Text(
              item.comments,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Footer: Timestamp, Review Toggle, and Delete
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${item.timeAgo} • ${DateFormat('dd MMM yyyy, hh:mm a').format(item.submittedAt)}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      provider.toggleFeedbackReviewed(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Text(item.isReviewed ? 'Marked as Pending Review' : 'Marked as Reviewed!'),
                        ),
                      );
                    },
                    icon: Icon(
                      item.isReviewed ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: item.isReviewed ? AppColors.textSecondary : const Color(0xFF10B981),
                    ),
                    label: Text(
                      item.isReviewed ? 'Mark as Pending' : 'Mark Reviewed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.isReviewed ? AppColors.textSecondary : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.danger,
                    tooltip: 'Delete Feedback',
                    onPressed: () => _showDeleteConfirmDialog(context, item, provider),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, FeedbackModel item, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review?'),
        content: Text('Are you sure you want to permanently delete review from "${item.userName}"? This removes the rating from Firestore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteFeedback(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback permanently deleted')),
              );
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdminProvider provider) {
    if (_searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedStarRating != null || _selectedReviewStatus != 'All') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_alt_off_rounded, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Reviews Match Selection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try relaxing your filter criteria or search keyword.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _selectedStarRating = null;
                  _selectedReviewStatus = 'All';
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
            const Icon(Icons.rate_review_outlined, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No User Reviews in Database',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your Firestore "feedbacks" collection currently has no entries.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final count = await provider.seedSampleFeedbacks();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Successfully loaded $count realistic user reviews into Firestore!'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Seed Sample User Reviews'),
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

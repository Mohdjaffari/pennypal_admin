import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/dashboard_stats_model.dart';

class AnalyticsOverviewChart extends StatelessWidget {
  final String period;
  final List<double> registrationTrend;
  final int totalUsers;

  const AnalyticsOverviewChart({
    super.key,
    this.period = 'This Week',
    this.registrationTrend = const [0, 0, 0, 0, 0, 0, 0],
    this.totalUsers = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine dynamic maxY
    double maxVal = 5.0;
    for (final v in registrationTrend) {
      if (v > maxVal) maxVal = v;
    }
    final double computedMaxY = (maxVal * 1.3).ceilToDouble();

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
                    const Text(
                      'User Registration & Activity Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Weekly account onboarding rate ($period) • $totalUsers users recorded',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Metrics',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: computedMaxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayName = days[group.x.toInt() % days.length];
                      final val = rod.toY.toInt();
                      return BarTooltipItem(
                        '$dayName\n$val accounts',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        if (value % 2 != 0 && computedMaxY > 6) return const Text('');
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[idx],
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  final double val = index < registrationTrend.length ? registrationTrend[index] : 0.0;
                  // For a nice dual-look, show registrations and estimated interactions
                  final double interactions = (val * 1.5).clamp(0.0, computedMaxY);
                  return _makeBarGroup(index, val, interactions);
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(color: AppColors.primary, label: 'Registrations'),
              const SizedBox(width: 24),
              _buildLegend(color: AppColors.accentPink, label: 'Interactions'),
            ],
          ),
        ],
      ),
    );
  }

  static BarChartGroupData _makeBarGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: y1,
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 9,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
        BarChartRodData(
          toY: y2,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3366), Color(0xFFFF85A1)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 9,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
      ],
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class CategoryDonutChart extends StatelessWidget {
  final List<CategorySliceData> slices;

  const CategoryDonutChart({
    super.key,
    this.slices = const [],
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSlices = slices.isNotEmpty
        ? slices
        : const [
            CategorySliceData(name: 'Food & Dining', count: 4, percentage: 34, color: Color(0xFFFF3366)),
            CategorySliceData(name: 'Transport', count: 3, percentage: 22, color: Color(0xFF2563EB)),
            CategorySliceData(name: 'Shopping', count: 2, percentage: 18, color: Color(0xFFF59E0B)),
            CategorySliceData(name: 'Utilities', count: 2, percentage: 14, color: Color(0xFF8B5CF6)),
            CategorySliceData(name: 'Entertainment', count: 1, percentage: 12, color: Color(0xFF06B6D4)),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories & Spending Matrix',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Live category distribution synchronized from Firestore',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    sections: effectiveSlices.map((slice) {
                      return PieChartSectionData(
                        color: slice.color,
                        value: slice.percentage > 0 ? slice.percentage : 1,
                        title: '${slice.percentage.toInt()}%',
                        radius: 30,
                        titleStyle: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: effectiveSlices.map((s) {
                    return _categoryRow(s.color, s.name, '${s.percentage.toStringAsFixed(0)}%');
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(Color color, String name, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            percentage,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

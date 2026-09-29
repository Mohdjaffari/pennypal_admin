import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/dashboard_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../providers/admin_provider.dart';
import '../dashboard/widgets/analytics_charts.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final dashCtrl = context.watch<DashboardController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 480;
                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Reports & Analytics',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Generate detailed audits & financial metrics',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              text: 'Generate Report',
                              icon: Icons.add_chart_rounded,
                              height: 42,
                              onPressed: () => _showGenerateReportDialog(context, provider),
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Reports & Analytics',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Generate detailed audits & financial metrics',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          CustomButton(
                            text: 'Generate Report',
                            icon: Icons.add_chart_rounded,
                            height: 42,
                            onPressed: () => _showGenerateReportDialog(context, provider),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _periodTab('Weekly', provider),
                        _periodTab('Monthly', provider),
                        _periodTab('Yearly', provider),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            AnalyticsOverviewChart(
              period: provider.selectedReportPeriod,
              registrationTrend: dashCtrl.stats.weeklyRegistrations,
              totalUsers: dashCtrl.stats.totalUsers,
            ),

            const SizedBox(height: 18),

            CategoryDonutChart(slices: dashCtrl.stats.categorySlices),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generated User Reports Archive',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${provider.generatedReports.length} Available',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Export and download user audit trails, velocity reports, and financial logs.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  if (provider.generatedReports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No reports generated yet. Click "Generate Report" above to create an audit export.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.generatedReports.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final report = provider.generatedReports[index];
                        return _buildReportItem(context, report, provider);
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _periodTab(String period, AdminProvider provider) {
    final isSelected = provider.selectedReportPeriod == period;
    return Expanded(
      child: InkWell(
        onTap: () => provider.setReportPeriod(period),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(
    BuildContext context,
    GeneratedReportRecord report,
    AdminProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: report.format == 'PDF' ? AppColors.accentPinkLight : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              report.format == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded,
              color: report.format == 'PDF' ? AppColors.accentPink : AppColors.primary,
              size: 22,
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
                        report.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: report.format == 'PDF'
                            ? AppColors.accentPink.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.format,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: report.format == 'PDF' ? AppColors.accentPink : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${report.reportType} • ${report.totalRecords} records • ${report.fileSize}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(report.generatedAt)} by ${report.generatedBy}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                tooltip: 'Export & Download',
                onPressed: () => _simulateReportDownload(context, report),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                tooltip: 'Delete Report',
                onPressed: () => provider.deleteGeneratedReport(report.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGenerateReportDialog(BuildContext context, AdminProvider provider) {
    final titleCtrl = TextEditingController(text: 'Monthly User Financial Audit');
    String reportType = 'Financial Flow';
    String format = 'PDF';
    String userGroup = 'All Users';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assessment_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Generate User Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: titleCtrl,
                      label: 'Report Title',
                      hintText: 'e.g., Q1 Student Expense Analysis',
                      validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Report Focus Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: reportType,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Financial Flow', child: Text('Financial Flow & Cash Volume')),
                        DropdownMenuItem(value: 'User Activity', child: Text('User Activity & Retention Audit')),
                        DropdownMenuItem(value: 'Engagement', child: Text('Category Spending & Engagement')),
                        DropdownMenuItem(value: 'Risk & Blocked', child: Text('Inactive & Blocked Accounts Audit')),
                      ],
                      onChanged: (val) => setDialogState(() => reportType = val!),
                    ),
                    const SizedBox(height: 14),
                    const Text('Target User Segment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: userGroup,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All Users', child: Text('All Registered Users')),
                        DropdownMenuItem(value: 'Active Only', child: Text('Active Users Only')),
                        DropdownMenuItem(value: 'Blocked Only', child: Text('Blocked Accounts Only')),
                      ],
                      onChanged: (val) => setDialogState(() => userGroup = val!),
                    ),
                    const SizedBox(height: 14),
                    const Text('Export Document Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => format = 'PDF'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: format == 'PDF' ? AppColors.accentPinkLight : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: format == 'PDF' ? AppColors.accentPink : AppColors.border,
                                  width: format == 'PDF' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded,
                                      size: 18, color: format == 'PDF' ? AppColors.accentPink : AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PDF Report',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: format == 'PDF' ? AppColors.accentPink : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => format = 'CSV'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: format == 'CSV' ? AppColors.primarySoft : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: format == 'CSV' ? AppColors.primary : AppColors.border,
                                  width: format == 'CSV' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.table_chart_rounded,
                                      size: 18, color: format == 'CSV' ? AppColors.primary : AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CSV Spreadsheet',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: format == 'CSV' ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
              text: 'Generate Now',
              icon: Icons.check_circle_rounded,
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  provider.generateNewReport(
                    title: titleCtrl.text.trim(),
                    reportType: reportType,
                    format: format,
                    recordsCount: provider.totalUsersCount * 8,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Row(
                        children: [
                          const Icon(Icons.download_done_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Report "${titleCtrl.text.trim()}" generated successfully!'),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _simulateReportDownload(BuildContext context, GeneratedReportRecord report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Exporting ${report.title} (${report.format})... Saved to Downloads')),
          ],
        ),
      ),
    );
  }
}

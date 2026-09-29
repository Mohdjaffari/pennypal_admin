class ReportFilter {
  final String period; // 'Weekly', 'Monthly', 'Yearly'
  final DateTime startDate;
  final DateTime endDate;
  final String? userStatus; // 'All', 'Active', 'Blocked'
  final String? category;

  ReportFilter({
    this.period = 'Monthly',
    required this.startDate,
    required this.endDate,
    this.userStatus = 'All',
    this.category,
  });
}

class GeneratedReportRecord {
  final String id;
  final String title;
  final String reportType; // 'User Activity', 'Financial Flow', 'Audit Log', 'Engagement'
  final DateTime generatedAt;
  final String generatedBy;
  final int totalRecords;
  final String fileSize;
  final String format; // 'PDF', 'CSV', 'JSON'

  GeneratedReportRecord({
    required this.id,
    required this.title,
    required this.reportType,
    required this.generatedAt,
    required this.generatedBy,
    required this.totalRecords,
    required this.fileSize,
    required this.format,
  });

  factory GeneratedReportRecord.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return GeneratedReportRecord(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? 'Generated Report',
      reportType: map['reportType'] ?? 'General',
      generatedAt: parseDate(map['generatedAt'] ?? map['createdAt']),
      generatedBy: map['generatedBy'] ?? 'Admin',
      totalRecords: (map['totalRecords'] as num?)?.toInt() ?? 0,
      fileSize: map['fileSize'] ?? '1.0 MB',
      format: map['format'] ?? 'PDF',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'reportType': reportType,
      'generatedAt': generatedAt.toIso8601String(),
      'generatedBy': generatedBy,
      'totalRecords': totalRecords,
      'fileSize': fileSize,
      'format': format,
    };
  }
}

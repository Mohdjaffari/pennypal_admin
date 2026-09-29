class AdminSettingsModel {
  bool isDarkMode;
  bool isNotificationsEnabled;
  bool isEmailAlertsEnabled;
  bool isSoundAndHaptics;
  String language;
  String autoBackupFrequency;
  bool isMaintenanceMode;
  bool isAiAssistantSync;
  int sessionTimeoutMinutes;
  String auditLogLevel;
  String currencyCode;

  AdminSettingsModel({
    this.isDarkMode = false,
    this.isNotificationsEnabled = true,
    this.isEmailAlertsEnabled = true,
    this.isSoundAndHaptics = true,
    this.language = 'English (US)',
    this.autoBackupFrequency = 'Daily (02:00 AM)',
    this.isMaintenanceMode = false,
    this.isAiAssistantSync = true,
    this.sessionTimeoutMinutes = 30,
    this.auditLogLevel = 'Standard (Recommended)',
    this.currencyCode = 'PKR (Rs.)',
  });

  AdminSettingsModel copyWith({
    bool? isDarkMode,
    bool? isNotificationsEnabled,
    bool? isEmailAlertsEnabled,
    bool? isSoundAndHaptics,
    String? language,
    String? autoBackupFrequency,
    bool? isMaintenanceMode,
    bool? isAiAssistantSync,
    int? sessionTimeoutMinutes,
    String? auditLogLevel,
    String? currencyCode,
  }) {
    return AdminSettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      isEmailAlertsEnabled: isEmailAlertsEnabled ?? this.isEmailAlertsEnabled,
      isSoundAndHaptics: isSoundAndHaptics ?? this.isSoundAndHaptics,
      language: language ?? this.language,
      autoBackupFrequency: autoBackupFrequency ?? this.autoBackupFrequency,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      isAiAssistantSync: isAiAssistantSync ?? this.isAiAssistantSync,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      auditLogLevel: auditLogLevel ?? this.auditLogLevel,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  factory AdminSettingsModel.fromMap(Map<String, dynamic> map) {
    return AdminSettingsModel(
      isDarkMode: map['isDarkMode'] ?? false,
      isNotificationsEnabled: map['isNotificationsEnabled'] ?? true,
      isEmailAlertsEnabled: map['isEmailAlertsEnabled'] ?? true,
      isSoundAndHaptics: map['isSoundAndHaptics'] ?? true,
      language: map['language'] ?? 'English (US)',
      autoBackupFrequency: map['autoBackupFrequency'] ?? 'Daily (02:00 AM)',
      isMaintenanceMode: map['isMaintenanceMode'] ?? false,
      isAiAssistantSync: map['isAiAssistantSync'] ?? true,
      sessionTimeoutMinutes: (map['sessionTimeoutMinutes'] as num?)?.toInt() ?? 30,
      auditLogLevel: map['auditLogLevel'] ?? 'Standard (Recommended)',
      currencyCode: map['currencyCode'] ?? 'PKR (Rs.)',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'isNotificationsEnabled': isNotificationsEnabled,
      'isEmailAlertsEnabled': isEmailAlertsEnabled,
      'isSoundAndHaptics': isSoundAndHaptics,
      'language': language,
      'autoBackupFrequency': autoBackupFrequency,
      'isMaintenanceMode': isMaintenanceMode,
      'isAiAssistantSync': isAiAssistantSync,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'auditLogLevel': auditLogLevel,
      'currencyCode': currencyCode,
    };
  }
}

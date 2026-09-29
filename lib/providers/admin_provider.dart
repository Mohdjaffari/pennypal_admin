import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/learning_model.dart';
import '../models/faq_model.dart';
import '../models/contact_model.dart';
import '../models/feedback_model.dart';
import '../models/category_model.dart';
import '../models/report_model.dart';
import '../models/admin_profile_model.dart';
import '../models/admin_settings_model.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/category_service.dart';
import '../services/learning_service.dart';
import '../services/faq_service.dart';
import '../services/contact_service.dart';
import '../services/feedback_service.dart';
import '../services/report_service.dart';
import '../services/admin_profile_service.dart';
import '../services/notification_service.dart';

class AdminProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();
  final LearningService _learningService = LearningService();
  final FaqService _faqService = FaqService();
  final ContactService _contactService = ContactService();
  final FeedbackService _feedbackService = FeedbackService();
  final ReportService _reportService = ReportService();
  final AdminProfileService _adminProfileService = AdminProfileService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _usersSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _learningSub;
  StreamSubscription? _faqsSub;
  StreamSubscription? _contactSub;
  StreamSubscription? _feedbackSub;
  StreamSubscription? _reportsSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _notificationsSub;

  AdminProvider() {
    initLiveDatabaseStreams();
  }

  void initLiveDatabaseStreams() {
    _cancelSubscriptions();

    try {
      _usersSub = _userService.getUsersStream().listen((snapshot) {
        _users = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), docId: doc.id)).toList();
        notifyListeners();
      }, onError: (e) => debugPrint("AdminProvider: Users stream error: $e"));

      _categoriesSub = _categoryService.getCategoriesStream().listen((snapshot) {
        _categories = snapshot.docs.map((doc) => CategoryModel.fromMap(doc.data(), docId: doc.id)).toList();
        notifyListeners();
      }, onError: (e) => debugPrint("AdminProvider: Categories stream error: $e"));

      _learningSub = _learningService.getLearningStream().listen((snapshot) {
        _learningContents = snapshot.docs.map((doc) => LearningContentModel.fromMap(doc.data(), docId: doc.id)).toList();
        notifyListeners();
      }, onError: (e) => debugPrint("AdminProvider: Learning stream error: $e"));

      _faqsSub = _faqService.getFaqsStream().listen((snapshot) {
        _faqs = snapshot.docs.map((doc) => FaqModel.fromMap(doc.data(), docId: doc.id)).toList();
        _faqs.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        notifyListeners();
      }, onError: (e) => debugPrint("AdminProvider: FAQs stream error: $e"));

      _isContactLoading = true;
      _contactSub = _contactService.getContactMessagesStream().listen((snapshot) {
        _contactMessages = snapshot.docs.map((doc) => ContactMessageModel.fromMap(doc.data(), docId: doc.id)).toList();
        _contactMessages.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        _isContactLoading = false;
        _contactError = null;
        notifyListeners();
      }, onError: (e) {
        debugPrint("AdminProvider: Contact stream error: $e");
        _isContactLoading = false;
        _contactError = e.toString();
        notifyListeners();
      });

      _isFeedbackLoading = true;
      _feedbackSub = _feedbackService.getFeedbacksStream().listen((snapshot) {
        _feedbacks = snapshot.docs.map((doc) => FeedbackModel.fromMap(doc.data(), docId: doc.id)).toList();
        _feedbacks.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        _isFeedbackLoading = false;
        _feedbackError = null;
        notifyListeners();
      }, onError: (e) {
        debugPrint("AdminProvider: Feedback stream error: $e");
        _isFeedbackLoading = false;
        _feedbackError = e.toString();
        notifyListeners();
      });

      _reportsSub = _reportService.getReportsStream().listen((snapshot) {
        _generatedReports = snapshot.docs.map((doc) => GeneratedReportRecord.fromMap(doc.data(), docId: doc.id)).toList();
        notifyListeners();
      }, onError: (e) => debugPrint("AdminProvider: Reports stream error: $e"));

      _settingsSub = _adminProfileService.getAdminSettingsStream().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          _adminSettings = AdminSettingsModel.fromMap(snapshot.data()!);
          notifyListeners();
        }
      }, onError: (e) => debugPrint("AdminProvider: Settings stream error: $e"));

      _isNotificationsLoading = true;
      _notificationsSub = _notificationService.getNotificationsStream().listen((snapshot) {
        _notifications = snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), docId: doc.id))
            .toList();
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isNotificationsLoading = false;
        _notificationsError = null;
        notifyListeners();
      }, onError: (e) {
        debugPrint("AdminProvider: Notifications stream error: $e");
        _isNotificationsLoading = false;
        _notificationsError = e.toString();
        notifyListeners();
      });
    } catch (e) {
      debugPrint("AdminProvider: Exception setting up database listeners: $e");
    }
  }

  void _cancelSubscriptions() {
    _usersSub?.cancel();
    _categoriesSub?.cancel();
    _learningSub?.cancel();
    _faqsSub?.cancel();
    _contactSub?.cancel();
    _feedbackSub?.cancel();
    _reportsSub?.cancel();
    _settingsSub?.cancel();
    _notificationsSub?.cancel();
  }

  // Navigation State
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  String _userSearchQuery = '';
  String _userStatusFilter = 'All';

  String get userSearchQuery => _userSearchQuery;
  String get userStatusFilter => _userStatusFilter;

  void setUserSearchQuery(String query) {
    _userSearchQuery = query;
    notifyListeners();
  }

  void setUserStatusFilter(String filter) {
    _userStatusFilter = filter;
    notifyListeners();
  }

  List<UserModel> _users = [];
  List<UserModel> get users => List.unmodifiable(_users);

  List<UserModel> get filteredUsers {
    return _users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          user.phone.contains(_userSearchQuery);

      if (_userStatusFilter == 'Active') {
        return matchesSearch && !user.isBlocked;
      } else if (_userStatusFilter == 'Blocked') {
        return matchesSearch && user.isBlocked;
      }
      return matchesSearch;
    }).toList();
  }

  void addUser(UserModel user) {
    _users.insert(0, user);
    notifyListeners();
  }

  void updateUser(UserModel updatedUser) {
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyListeners();
    }
  }

  Future<void> toggleBlockUser(String userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final newStatus = !_users[index].isBlocked;
      _users[index] = _users[index].copyWith(isBlocked: newStatus);
      notifyListeners();
      await _userService.toggleBlockUserOnline(userId, newStatus);
    }
  }

  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
    await _userService.deleteUserOnline(userId);
  }

  String _learningCategoryFilter = 'All';
  String get learningCategoryFilter => _learningCategoryFilter;

  void setLearningCategoryFilter(String category) {
    _learningCategoryFilter = category;
    notifyListeners();
  }

  List<LearningContentModel> _learningContents = [];
  List<LearningContentModel> get learningContents => List.unmodifiable(_learningContents);

  List<LearningContentModel> get filteredLearning {
    if (_learningCategoryFilter == 'All') return _learningContents;
    return _learningContents.where((item) => item.category.toLowerCase() == _learningCategoryFilter.toLowerCase()).toList();
  }

  void addLearningContent(LearningContentModel item) {
    _learningContents.insert(0, item);
    notifyListeners();
  }

  void updateLearningContent(LearningContentModel updated) {
    final index = _learningContents.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _learningContents[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleFeaturedLearning(String id) async {
    final index = _learningContents.indexWhere((item) => item.id == id);
    if (index != -1) {
      final newFeatured = !_learningContents[index].isFeatured;
      _learningContents[index] = _learningContents[index].copyWith(isFeatured: newFeatured);
      notifyListeners();
      await _learningService.toggleFeaturedOnline(id, newFeatured);
    }
  }

  Future<void> deleteLearningContent(String id) async {
    _learningContents.removeWhere((item) => item.id == id);
    notifyListeners();
    await _learningService.deleteLearningOnline(id);
  }

  String _faqCategoryFilter = 'All';
  String get faqCategoryFilter => _faqCategoryFilter;

  void setFaqCategoryFilter(String category) {
    _faqCategoryFilter = category;
    notifyListeners();
  }

  List<FaqModel> _faqs = [];
  List<FaqModel> get faqs => List.unmodifiable(_faqs);

  List<FaqModel> get filteredFaqs {
    if (_faqCategoryFilter == 'All') return _faqs;
    return _faqs.where((faq) => faq.category.toLowerCase() == _faqCategoryFilter.toLowerCase()).toList();
  }

  void addFaq(FaqModel faq) {
    _faqs.insert(0, faq);
    notifyListeners();
  }

  void updateFaq(FaqModel updated) {
    final index = _faqs.indexWhere((f) => f.id == updated.id);
    if (index != -1) {
      _faqs[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleFaqActive(String id) async {
    final index = _faqs.indexWhere((f) => f.id == id);
    if (index != -1) {
      final newActive = !_faqs[index].isActive;
      _faqs[index] = _faqs[index].copyWith(isActive: newActive);
      notifyListeners();
      await _faqService.toggleFaqStatusOnline(id, newActive);
    }
  }

  Future<void> deleteFaq(String id) async {
    _faqs.removeWhere((f) => f.id == id);
    notifyListeners();
    await _faqService.deleteFaqOnline(id);
  }

  bool _isContactLoading = false;
  bool get isContactLoading => _isContactLoading;
  String? _contactError;
  String? get contactError => _contactError;

  List<ContactMessageModel> _contactMessages = [];
  List<ContactMessageModel> get contactMessages => List.unmodifiable(_contactMessages);

  Future<void> refreshContactMessages() async {
    _isContactLoading = true;
    _contactError = null;
    notifyListeners();
    try {
      final list = await _contactService.fetchContactMessagesOnce();
      _contactMessages = list;
    } catch (e) {
      _contactError = e.toString();
    } finally {
      _isContactLoading = false;
      notifyListeners();
    }
  }

  Future<int> seedSampleContactMessages() async {
    final count = await _contactService.seedSampleMessagesIfEmpty();
    if (count > 0) {
      await refreshContactMessages();
    }
    return count;
  }

  Future<bool> createContactMessage(ContactMessageModel model) async {
    final success = await _contactService.createContactMessage(model);
    if (success) {
      await refreshContactMessages();
    }
    return success;
  }

  Future<void> updateContactStatus(String id, ContactStatus newStatus) async {
    final index = _contactMessages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _contactMessages[index].status = newStatus;
      notifyListeners();
      await _contactService.updateStatus(id, newStatus);
    }
  }

  Future<void> replyToContact(String id, String reply) async {
    final index = _contactMessages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _contactMessages[index].adminReply = reply;
      _contactMessages[index].repliedAt = DateTime.now();
      _contactMessages[index].status = ContactStatus.resolved;
      notifyListeners();
      await _contactService.replyToMessage(id, reply, adminEmail: adminProfile.email);
    }
  }

  Future<void> deleteContactMessage(String id) async {
    _contactMessages.removeWhere((m) => m.id == id);
    notifyListeners();
    await _contactService.deleteMessage(id);
  }

  bool _isFeedbackLoading = false;
  bool get isFeedbackLoading => _isFeedbackLoading;
  String? _feedbackError;
  String? get feedbackError => _feedbackError;

  List<FeedbackModel> _feedbacks = [];
  List<FeedbackModel> get feedbacks => List.unmodifiable(_feedbacks);

  Future<void> refreshFeedbacks() async {
    _isFeedbackLoading = true;
    _feedbackError = null;
    notifyListeners();
    try {
      final list = await _feedbackService.fetchFeedbacksOnce();
      _feedbacks = list;
    } catch (e) {
      _feedbackError = e.toString();
    } finally {
      _isFeedbackLoading = false;
      notifyListeners();
    }
  }

  Future<int> seedSampleFeedbacks() async {
    final count = await _feedbackService.seedSampleFeedbacksIfEmpty();
    if (count > 0) {
      await refreshFeedbacks();
    }
    return count;
  }

  Future<bool> createFeedback(FeedbackModel model) async {
    final success = await _feedbackService.createFeedback(model);
    if (success) {
      await refreshFeedbacks();
    }
    return success;
  }

  Future<void> toggleFeedbackReviewed(String id) async {
    final index = _feedbacks.indexWhere((f) => f.id == id);
    if (index != -1) {
      final newStatus = !_feedbacks[index].isReviewed;
      _feedbacks[index] = _feedbacks[index].copyWith(isReviewed: newStatus);
      notifyListeners();
      await _feedbackService.toggleFeedbackReviewed(id, newStatus);
    }
  }

  Future<void> deleteFeedback(String id) async {
    _feedbacks.removeWhere((f) => f.id == id);
    notifyListeners();
    await _feedbackService.deleteFeedback(id);
  }

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => List.unmodifiable(_categories);

  void addCategory(CategoryModel category) {
    _categories.insert(0, category);
    notifyListeners();
  }

  void updateCategory(CategoryModel updated) {
    final index = _categories.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _categories[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleCategoryVisibility(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      final newVisible = !_categories[index].isVisibleToUser;
      _categories[index] = _categories[index].copyWith(isVisibleToUser: newVisible);
      notifyListeners();
      await _categoryService.toggleVisibilityOnline(id, newVisible);
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    await _categoryService.deleteCategory(id);
  }

  String _selectedReportPeriod = 'Monthly';
  String get selectedReportPeriod => _selectedReportPeriod;

  void setReportPeriod(String period) {
    _selectedReportPeriod = period;
    notifyListeners();
  }

  List<GeneratedReportRecord> _generatedReports = [];
  List<GeneratedReportRecord> get generatedReports => List.unmodifiable(_generatedReports);

  Future<void> generateNewReport({
    required String title,
    required String reportType,
    required String format,
    required int recordsCount,
  }) async {
    final newReport = GeneratedReportRecord(
      id: 'REP-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      reportType: reportType,
      generatedAt: DateTime.now(),
      generatedBy: 'Admin (${adminProfile.name})',
      totalRecords: recordsCount,
      fileSize: '${(1.2 + (_generatedReports.length * 0.4)).toStringAsFixed(1)} MB',
      format: format,
    );
    _generatedReports.insert(0, newReport);
    notifyListeners();
    await _reportService.saveReport(newReport);
  }

  Future<void> deleteGeneratedReport(String id) async {
    _generatedReports.removeWhere((r) => r.id == id);
    notifyListeners();
    await _reportService.deleteReport(id);
  }

  int get totalUsersCount => _users.length;
  int get activeUsersCount => _users.where((u) => !u.isBlocked).length;
  int get blockedUsersCount => _users.where((u) => u.isBlocked).length;

  double get totalTrackedBalance =>
      _users.fold(0.0, (sum, u) => sum + u.totalBalance);

  double get totalTrackedExpenses =>
      _users.fold(0.0, (sum, u) => sum + u.totalExpenses);

  double get totalTrackedSavings =>
      _users.fold(0.0, (sum, u) => sum + u.savings);

  int get pendingFeedbacksCount =>
      _feedbacks.where((f) => !f.isReviewed).length;

  int get reviewedFeedbacksCount =>
      _feedbacks.where((f) => f.isReviewed).length;

  double get averageFeedbackRating => _feedbacks.isEmpty
      ? 0.0
      : _feedbacks.fold(0.0, (sum, f) => sum + f.rating) / _feedbacks.length;

  Map<int, int> get feedbackStarCounts {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final f in _feedbacks) {
      final r = f.rating.clamp(1, 5);
      counts[r] = (counts[r] ?? 0) + 1;
    }
    return counts;
  }

  Map<int, double> get feedbackStarPercentages {
    final total = _feedbacks.length;
    final counts = feedbackStarCounts;
    if (total == 0) {
      return {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0};
    }
    return {
      5: (counts[5]! / total) * 100,
      4: (counts[4]! / total) * 100,
      3: (counts[3]! / total) * 100,
      2: (counts[2]! / total) * 100,
      1: (counts[1]! / total) * 100,
    };
  }

  int get newContactMessagesCount =>
      _contactMessages.where((c) => c.status == ContactStatus.newMsg).length;

  int get inProgressContactMessagesCount =>
      _contactMessages.where((c) => c.status == ContactStatus.inProgress).length;

  int get resolvedContactMessagesCount =>
      _contactMessages.where((c) => c.status == ContactStatus.resolved).length;

  double get contactResponseRate {
    if (_contactMessages.isEmpty) return 100.0;
    final responded = _contactMessages.where((c) => c.status == ContactStatus.resolved || c.adminReply != null).length;
    return (responded / _contactMessages.length) * 100;
  }

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool val) {
    _isAuthenticated = val;
    notifyListeners();
  }

  bool login(String email, String password) {
    if (email.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      adminProfile.lastLogin = DateTime.now();
      _currentNavIndex = 0;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    AuthService.instance.logout();
    notifyListeners();
  }

  AdminProfileModel? _adminProfile;

  AdminProfileModel get adminProfile {
    _adminProfile ??= AdminProfileModel(
      id: 'ADM-001',
      name: 'PennyPal Administrator',
      email: 'admin@pennypal.app',
      phone: '+92 300 0000000',
      role: 'Super Administrator',
      department: 'Finance & Systems Ops',
      avatarUrl: '',
      joinedDate: DateTime.now(),
      lastLogin: DateTime.now(),
      is2faEnabled: true,
      bio: 'PennyPal Core Systems Administrator. Responsible for system governance, content, and data integrity.',
    );
    return _adminProfile!;
  }

  Future<void> updateAdminProfile({
    required String name,
    required String phone,
    String? avatarUrl,
    String? department,
    String? bio,
  }) async {
    final p = adminProfile;
    p.name = name;
    p.phone = phone;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      p.avatarUrl = avatarUrl;
    }
    if (department != null) p.department = department;
    if (bio != null) p.bio = bio;
    // Email is strictly non-editable to preserve primary system identifier
    notifyListeners();
    await _adminProfileService.saveAdminProfile(p);
  }

  /// Uploads admin profile picture to Cloudinary and saves URL in Firestore
  Future<String?> uploadAdminAvatar(Uint8List imageBytes, String fileName) async {
    try {
      final secureUrl = await _userService.uploadAvatar(imageBytes, fileName);
      if (secureUrl.isNotEmpty) {
        final p = adminProfile;
        p.avatarUrl = secureUrl;
        notifyListeners();
        await _adminProfileService.saveAdminProfile(p);
        return secureUrl;
      }
      return null;
    } catch (e) {
      debugPrint("Error uploading admin avatar: $e");
      return null;
    }
  }

  /// Updates admin password in Firebase Auth
  Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await AuthService.instance.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> toggle2fa() async {
    final p = adminProfile;
    p.is2faEnabled = !p.is2faEnabled;
    notifyListeners();
    await _adminProfileService.saveAdminProfile(p);
  }

  AdminSettingsModel? _adminSettings;

  AdminSettingsModel get adminSettings {
    _adminSettings ??= AdminSettingsModel();
    return _adminSettings!;
  }

  void _saveSettings() {
    _adminProfileService.saveAdminSettings(adminSettings);
  }

  void toggleDarkMode(bool val) {
    adminSettings.isDarkMode = val;
    notifyListeners();
    _saveSettings();
  }

  void toggleNotifications(bool val) {
    adminSettings.isNotificationsEnabled = val;
    notifyListeners();
    _saveSettings();
  }

  void toggleEmailAlerts(bool val) {
    adminSettings.isEmailAlertsEnabled = val;
    notifyListeners();
    _saveSettings();
  }

  void toggleSoundAndHaptics(bool val) {
    adminSettings.isSoundAndHaptics = val;
    notifyListeners();
    _saveSettings();
  }

  void toggleMaintenanceMode(bool val) {
    adminSettings.isMaintenanceMode = val;
    notifyListeners();
    _saveSettings();
  }

  void toggleAiAssistantSync(bool val) {
    adminSettings.isAiAssistantSync = val;
    notifyListeners();
    _saveSettings();
  }

  void setLanguage(String lang) {
    adminSettings.language = lang;
    notifyListeners();
    _saveSettings();
  }

  void setAutoBackupFrequency(String freq) {
    adminSettings.autoBackupFrequency = freq;
    notifyListeners();
    _saveSettings();
  }

  void setSessionTimeout(int minutes) {
    adminSettings.sessionTimeoutMinutes = minutes;
    notifyListeners();
    _saveSettings();
  }

  void setAuditLogLevel(String level) {
    adminSettings.auditLogLevel = level;
    notifyListeners();
    _saveSettings();
  }

  void setCurrencyCode(String code) {
    adminSettings.currencyCode = code;
    notifyListeners();
    _saveSettings();
  }

  List<NotificationModel> _notifications = [];
  bool _isNotificationsLoading = true;
  String? _notificationsError;
  String _notificationFilter = 'All'; // 'All', 'Contact Inquiries', 'User Reviews', 'Unread'
  String _notificationSearchQuery = '';
  final Set<String> _locallyReadNotifIds = {};

  List<NotificationModel> get notifications => feedbackAndContactNotifications;
  bool get isNotificationsLoading => _isNotificationsLoading;
  String? get notificationsError => _notificationsError;
  String get notificationFilter => _notificationFilter;
  String get notificationSearchQuery => _notificationSearchQuery;

  /// Exclusively returns notifications for user feedback and contact messages sent by users:
  List<NotificationModel> get feedbackAndContactNotifications {
    // 1. Gather all existing explicit notifications of feedback & contact types
    final explicitNotifs = _notifications.where((n) =>
        n.type == NotificationType.contactMessage ||
        n.type == NotificationType.feedbackReceived).toList();

    final Set<String> existingRefIds = {};
    for (var n in explicitNotifs) {
      if (n.referenceId != null) {
        existingRefIds.add(n.referenceId!);
      }
      existingRefIds.add(n.id);
    }

    final List<NotificationModel> combined = [];
    for (var n in explicitNotifs) {
      final isLocallyRead = _locallyReadNotifIds.contains(n.id);
      combined.add(n.copyWith(isRead: n.isRead || isLocallyRead));
    }

    // 2. Synthesize notifications from actual feedback items if not already present
    for (var fb in _feedbacks) {
      if (!existingRefIds.contains(fb.id)) {
        final notifId = 'fb_${fb.id}';
        final isLocallyRead = _locallyReadNotifIds.contains(notifId) || fb.isReviewed;
        combined.add(NotificationModel(
          id: notifId,
          title: '${fb.rating}★ Review from ${fb.userName}',
          message: '${fb.feedbackType}: "${fb.comments.length > 90 ? '${fb.comments.substring(0, 90)}...' : fb.comments}"',
          type: NotificationType.feedbackReceived,
          target: NotificationTarget.admin,
          createdAt: fb.submittedAt,
          isRead: isLocallyRead,
          referenceId: fb.id,
          metadata: {
            'userName': fb.userName,
            'userEmail': fb.userEmail,
            'rating': fb.rating,
            'feedbackType': fb.feedbackType,
            'comments': fb.comments,
          },
        ));
        existingRefIds.add(fb.id);
      }
    }

    // 3. Synthesize notifications from actual contact inquiry items if not already present
    for (var msg in _contactMessages) {
      if (!existingRefIds.contains(msg.id)) {
        final notifId = 'contact_${msg.id}';
        final isLocallyRead = _locallyReadNotifIds.contains(notifId) || msg.status == ContactStatus.resolved;
        combined.add(NotificationModel(
          id: notifId,
          title: 'Customer Inquiry: ${msg.subject}',
          message: 'From ${msg.senderName} (${msg.senderEmail}): "${msg.message.length > 90 ? '${msg.message.substring(0, 90)}...' : msg.message}"',
          type: NotificationType.contactMessage,
          target: NotificationTarget.admin,
          createdAt: msg.submittedAt,
          isRead: isLocallyRead,
          referenceId: msg.id,
          metadata: {
            'senderName': msg.senderName,
            'senderEmail': msg.senderEmail,
            'subject': msg.subject,
            'message': msg.message,
            'status': msg.status.name,
          },
        ));
        existingRefIds.add(msg.id);
      }
    }

    // Sort newest first
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  int get unreadNotificationsCount =>
      feedbackAndContactNotifications.where((n) => !n.isRead).length;

  int get totalInquiryFeedbackNotificationsCount =>
      feedbackAndContactNotifications.length;

  int get contactInquiriesNotificationCount =>
      feedbackAndContactNotifications.where((n) => n.type == NotificationType.contactMessage).length;

  int get userReviewsNotificationCount =>
      feedbackAndContactNotifications.where((n) => n.type == NotificationType.feedbackReceived).length;

  List<NotificationModel> get filteredNotifications {
    var list = feedbackAndContactNotifications;

    // Filter by tab
    if (_notificationFilter == 'Contact Inquiries') {
      list = list.where((n) => n.type == NotificationType.contactMessage).toList();
    } else if (_notificationFilter == 'User Reviews') {
      list = list.where((n) => n.type == NotificationType.feedbackReceived).toList();
    } else if (_notificationFilter == 'Unread') {
      list = list.where((n) => !n.isRead).toList();
    }

    // Filter by search query
    if (_notificationSearchQuery.trim().isNotEmpty) {
      final q = _notificationSearchQuery.toLowerCase();
      list = list.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.message.toLowerCase().contains(q) ||
            n.typeLabel.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  void setNotificationFilter(String filter) {
    _notificationFilter = filter;
    notifyListeners();
  }

  void setNotificationSearchQuery(String query) {
    _notificationSearchQuery = query;
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String id) async {
    _locallyReadNotifIds.add(id);
    notifyListeners();
    try {
      if (!id.startsWith('fb_') && !id.startsWith('contact_')) {
        await _notificationService.markAsRead(id);
      }
    } catch (e) {
      debugPrint("Error marking notification read: $e");
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    for (var n in feedbackAndContactNotifications) {
      _locallyReadNotifIds.add(n.id);
    }
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await _notificationService.markAllAsRead();
    } catch (e) {
      debugPrint("Error marking all notifications read: $e");
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      if (!id.startsWith('fb_') && !id.startsWith('contact_')) {
        await _notificationService.deleteNotification(id);
      }
      _notifications.removeWhere((n) => n.id == id);
      _locallyReadNotifIds.remove(id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting notification: $e");
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      _notifications.clear();
      _locallyReadNotifIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing notifications: $e");
    }
  }

  Future<void> createBroadcastNotification({
    required String title,
    required String message,
    required NotificationType type,
    required NotificationTarget target,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notif = NotificationModel(
        id: '',
        title: title,
        message: message,
        type: type,
        target: target,
        createdAt: DateTime.now(),
        isRead: false,
        metadata: data,
      );
      await _notificationService.createNotification(notif);
    } catch (e) {
      debugPrint("Error creating broadcast notification: $e");
      rethrow;
    }
  }

  Future<void> seedSampleNotifications() async {
    try {
      _isNotificationsLoading = true;
      notifyListeners();
      await _notificationService.seedSampleNotificationsIfEmpty();
      _isNotificationsLoading = false;
      notifyListeners();
    } catch (e) {
      _isNotificationsLoading = false;
      notifyListeners();
      debugPrint("Error seeding notifications: $e");
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}

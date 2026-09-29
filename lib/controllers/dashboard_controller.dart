import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dashboard_stats_model.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/contact_model.dart';
import '../services/dashboard_service.dart';
import '../services/user_service.dart';

class DashboardController with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  final UserService _userService = UserService();

  DashboardStats _stats = DashboardStats();
  DashboardStats get stats => _stats;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isLiveConnected = false;
  bool get isLiveConnected => _isLiveConnected;

  StreamSubscription? _usersSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _learningSub;
  StreamSubscription? _faqsSub;
  StreamSubscription? _contactSub;

  List<UserModel> _cachedUsers = [];
  List<CategoryModel> _cachedCategories = [];
  int _cachedLearningCount = 0;
  int _cachedFeaturedLearningCount = 0;
  int _cachedFaqsCount = 0;
  int _cachedPendingInquiries = 0;
  int _cachedTotalInquiries = 0;
  List<ContactMessageModel> _cachedRecentInquiries = [];

  DashboardController() {
    init();
  }

  void init() {
    _isLoading = true;
    notifyListeners();

    fetchDashboardData();
    _listenToStreams();
  }

  void _listenToStreams() {
    _usersSub?.cancel();
    _categoriesSub?.cancel();
    _learningSub?.cancel();
    _faqsSub?.cancel();
    _contactSub?.cancel();

    try {
      _usersSub = _dashboardService.getUsersStream().listen(
        (snapshot) {
          _cachedUsers = snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), docId: doc.id);
          }).toList();
          _recomputeStats();
        },
        onError: (e) {
          debugPrint("DashboardController: Error in users stream: $e");
        },
      );

      _categoriesSub = _dashboardService.getCategoriesStream().listen(
        (snapshot) {
          _cachedCategories = snapshot.docs.map((doc) {
            return CategoryModel.fromMap(doc.data(), docId: doc.id);
          }).toList();
          _recomputeStats();
        },
        onError: (e) {
          debugPrint("DashboardController: Error in categories stream: $e");
        },
      );

      _learningSub = _dashboardService.getLearningStream().listen(
        (snapshot) {
          _cachedLearningCount = snapshot.docs.length;
          _cachedFeaturedLearningCount = snapshot.docs.where((d) => (d.data()['isFeatured'] == true)).length;
          _recomputeStats();
        },
        onError: (e) {
          debugPrint("DashboardController: Error in learning stream: $e");
        },
      );

      _faqsSub = _dashboardService.getFaqsStream().listen(
        (snapshot) {
          _cachedFaqsCount = snapshot.docs.length;
          _recomputeStats();
        },
        onError: (e) {
          debugPrint("DashboardController: Error in faqs stream: $e");
        },
      );

      _contactSub = _dashboardService.getContactStream().listen(
        (snapshot) {
          final inquiries = snapshot.docs.map((doc) {
            return ContactMessageModel.fromMap(doc.data(), docId: doc.id);
          }).toList();
          inquiries.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          _cachedRecentInquiries = inquiries.take(4).toList();
          _cachedPendingInquiries = inquiries.where((i) => i.status == ContactStatus.newMsg).length;
          _cachedTotalInquiries = inquiries.length;
          _recomputeStats();
        },
        onError: (e) {
          debugPrint("DashboardController: Error in contacts stream: $e");
        },
      );
    } catch (e) {
      debugPrint("DashboardController: Error setting up listeners: $e");
    }
  }

  void _recomputeStats() {
    _isLiveConnected = true;
    _isLoading = false;

    final sortedUsers = List<UserModel>.from(_cachedUsers)
      ..sort((a, b) => b.joinedDate.compareTo(a.joinedDate));

    final int totalUsers = sortedUsers.length;
    final int blockedUsers = sortedUsers.where((u) => u.isBlocked).length;
    final int activeUsers = totalUsers - blockedUsers;
    final double totalBalance = sortedUsers.fold(0.0, (acc, u) => acc + u.totalBalance);
    final List<UserModel> recentUsers = sortedUsers.take(5).toList();

    final List<double> weeklyRegistrations = [0, 0, 0, 0, 0, 0, 0];
    final now = DateTime.now();
    for (final u in sortedUsers) {
      final diff = now.difference(u.joinedDate).inDays;
      if (diff >= 0 && diff <= 7) {
        final dayIndex = (u.joinedDate.weekday - 1).clamp(0, 6);
        weeklyRegistrations[dayIndex] += 1;
      }
    }

    final Map<String, int> usersByRole = {};
    for (final u in sortedUsers) {
      final r = u.role.isEmpty ? 'Standard User' : u.role;
      usersByRole[r] = (usersByRole[r] ?? 0) + 1;
    }

    final int totalCategories = _cachedCategories.length;
    final int expenseCategories = _cachedCategories.where((c) => c.type.toLowerCase() == 'expense').length;
    final int incomeCategories = _cachedCategories.where((c) => c.type.toLowerCase() == 'income').length;

    final List<CategorySliceData> categorySlices = [];
    if (_cachedCategories.isNotEmpty) {
      final int sliceCount = _cachedCategories.length > 5 ? 5 : _cachedCategories.length;
      final double perSlice = 100.0 / _cachedCategories.length;
      for (int i = 0; i < sliceCount; i++) {
        final cat = _cachedCategories[i];
        categorySlices.add(
          CategorySliceData(
            name: cat.name,
            count: 1,
            percentage: double.parse(perSlice.toStringAsFixed(1)),
            color: cat.color,
          ),
        );
      }
      if (_cachedCategories.length > 5) {
        final otherCount = _cachedCategories.length - 5;
        final otherPct = double.parse((otherCount * perSlice).toStringAsFixed(1));
        categorySlices.add(
          CategorySliceData(
            name: 'Other ($otherCount)',
            count: otherCount,
            percentage: otherPct,
            color: const Color(0xFF64748B),
          ),
        );
      }
    }

    _stats = _stats.copyWith(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      blockedUsers: blockedUsers,
      totalPlatformBalance: totalBalance,
      recentUsers: recentUsers,
      weeklyRegistrations: weeklyRegistrations,
      usersByRole: usersByRole,
      totalCategories: totalCategories,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
      categorySlices: categorySlices,
      totalLearning: _cachedLearningCount,
      featuredLearning: _cachedFeaturedLearningCount,
      totalFaqs: _cachedFaqsCount,
      pendingInquiries: _cachedPendingInquiries,
      totalInquiries: _cachedTotalInquiries,
      recentInquiries: _cachedRecentInquiries,
      isFirestoreConnected: true,
      lastUpdated: DateTime.now(),
    );

    notifyListeners();
  }

  /// One-time manual or initial fetch from Firestore
  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _dashboardService.fetchDashboardDataOnline();
      if (result.isFirestoreConnected) {
        _stats = result;
        _isLiveConnected = true;
      }
    } catch (e) {
      debugPrint("DashboardController: Error fetching initial online stats: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles block status for a user directly from Dashboard recent users
  Future<bool> toggleBlockUser(UserModel user) async {
    final newStatus = !user.isBlocked;
    try {
      final ok = await _userService.toggleBlockUserOnline(user.id, newStatus);
      if (ok) {
        final idx = _cachedUsers.indexWhere((u) => u.id == user.id);
        if (idx != -1) {
          _cachedUsers[idx] = _cachedUsers[idx].copyWith(isBlocked: newStatus);
          _recomputeStats();
        }
      }
      return ok;
    } catch (e) {
      debugPrint("Error toggling user block from dashboard: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _categoriesSub?.cancel();
    _learningSub?.cancel();
    _faqsSub?.cancel();
    _contactSub?.cancel();
    super.dispose();
  }
}

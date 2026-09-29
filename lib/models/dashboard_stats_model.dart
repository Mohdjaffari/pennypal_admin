import 'package:flutter/material.dart';
import 'user_model.dart';
import 'contact_model.dart';

class CategorySliceData {
  final String name;
  final int count;
  final double percentage;
  final Color color;

  const CategorySliceData({
    required this.name,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int blockedUsers;
  final double totalPlatformBalance;
  final List<UserModel> recentUsers;
  final List<double> weeklyRegistrations; // 7 days (Mon to Sun)
  final Map<String, int> usersByRole;

  final int totalCategories;
  final int expenseCategories;
  final int incomeCategories;
  final List<CategorySliceData> categorySlices;

  final int totalLearning;
  final int featuredLearning;

  final int totalFaqs;

  final int pendingInquiries;
  final int totalInquiries;
  final List<ContactMessageModel> recentInquiries;

  final bool isFirestoreConnected;
  final DateTime lastUpdated;

  DashboardStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.blockedUsers = 0,
    this.totalPlatformBalance = 0.0,
    this.recentUsers = const [],
    this.weeklyRegistrations = const [0, 0, 0, 0, 0, 0, 0],
    this.usersByRole = const {},
    this.totalCategories = 0,
    this.expenseCategories = 0,
    this.incomeCategories = 0,
    this.categorySlices = const [],
    this.totalLearning = 0,
    this.featuredLearning = 0,
    this.totalFaqs = 0,
    this.pendingInquiries = 0,
    this.totalInquiries = 0,
    this.recentInquiries = const [],
    this.isFirestoreConnected = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  DashboardStats copyWith({
    int? totalUsers,
    int? activeUsers,
    int? blockedUsers,
    double? totalPlatformBalance,
    List<UserModel>? recentUsers,
    List<double>? weeklyRegistrations,
    Map<String, int>? usersByRole,
    int? totalCategories,
    int? expenseCategories,
    int? incomeCategories,
    List<CategorySliceData>? categorySlices,
    int? totalLearning,
    int? featuredLearning,
    int? totalFaqs,
    int? pendingInquiries,
    int? totalInquiries,
    List<ContactMessageModel>? recentInquiries,
    bool? isFirestoreConnected,
    DateTime? lastUpdated,
  }) {
    return DashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      totalPlatformBalance: totalPlatformBalance ?? this.totalPlatformBalance,
      recentUsers: recentUsers ?? this.recentUsers,
      weeklyRegistrations: weeklyRegistrations ?? this.weeklyRegistrations,
      usersByRole: usersByRole ?? this.usersByRole,
      totalCategories: totalCategories ?? this.totalCategories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      categorySlices: categorySlices ?? this.categorySlices,
      totalLearning: totalLearning ?? this.totalLearning,
      featuredLearning: featuredLearning ?? this.featuredLearning,
      totalFaqs: totalFaqs ?? this.totalFaqs,
      pendingInquiries: pendingInquiries ?? this.pendingInquiries,
      totalInquiries: totalInquiries ?? this.totalInquiries,
      recentInquiries: recentInquiries ?? this.recentInquiries,
      isFirestoreConnected: isFirestoreConnected ?? this.isFirestoreConnected,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

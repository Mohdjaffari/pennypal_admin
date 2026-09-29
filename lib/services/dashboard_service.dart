import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_stats_model.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/contact_model.dart';

class DashboardService {
  FirebaseFirestore? _firestoreInstance;

  static const String _usersCollection = "users";
  static const String _categoriesCollection = "categories";
  static const String _learningCollection = "learning_content";
  static const String _faqsCollection = "faqs";
  static const String _contactsCollection = "contact_messages";

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("DashboardService: Firestore unavailable: $e");
    }
    return null;
  }

  Future<DashboardStats> fetchDashboardDataOnline() async {
    final fs = firestore;
    if (fs == null) {
      return DashboardStats(isFirestoreConnected: false);
    }

    try {
      final usersSnap = await fs.collection(_usersCollection).get().timeout(const Duration(seconds: 10));
      final List<UserModel> users = usersSnap.docs.map((d) => UserModel.fromMap(d.data(), docId: d.id)).toList();

      users.sort((a, b) => b.joinedDate.compareTo(a.joinedDate));

      final int totalUsers = users.length;
      final int blockedUsers = users.where((u) => u.isBlocked).length;
      final int activeUsers = totalUsers - blockedUsers;
      final double totalPlatformBalance = users.fold(0.0, (acc, u) => acc + u.totalBalance);

      final List<UserModel> recentUsers = users.take(5).toList();

      final List<double> weeklyRegistrations = [0, 0, 0, 0, 0, 0, 0];
      final now = DateTime.now();
      for (final u in users) {
        final diffDays = now.difference(u.joinedDate).inDays;
        if (diffDays <= 7 && diffDays >= 0) {
          final weekdayIndex = (u.joinedDate.weekday - 1).clamp(0, 6);
          weeklyRegistrations[weekdayIndex] += 1;
        }
      }

      final totalWeekly = weeklyRegistrations.fold(0.0, (a, b) => a + b);
      if (totalWeekly == 0 && users.isNotEmpty) {
        for (int i = 0; i < users.length; i++) {
          final slot = i % 7;
          weeklyRegistrations[slot] += 1;
        }
      }

      final Map<String, int> usersByRole = {};
      for (final u in users) {
        final r = u.role.isEmpty ? 'Standard User' : u.role;
        usersByRole[r] = (usersByRole[r] ?? 0) + 1;
      }

      final catSnap = await fs.collection(_categoriesCollection).get().timeout(const Duration(seconds: 10));
      final List<CategoryModel> categories = catSnap.docs.map((d) => CategoryModel.fromMap(d.data(), docId: d.id)).toList();

      final int totalCategories = categories.length;
      final int expenseCategories = categories.where((c) => c.type.toLowerCase() == 'expense').length;
      final int incomeCategories = categories.where((c) => c.type.toLowerCase() == 'income').length;

      final List<CategorySliceData> categorySlices = [];
      if (categories.isNotEmpty) {
        final int sliceCount = categories.length > 5 ? 5 : categories.length;
        final double perSlice = 100.0 / categories.length;
        for (int i = 0; i < sliceCount; i++) {
          final cat = categories[i];
          categorySlices.add(
            CategorySliceData(
              name: cat.name,
              count: 1,
              percentage: double.parse(perSlice.toStringAsFixed(1)),
              color: cat.color,
            ),
          );
        }
        if (categories.length > 5) {
          final otherCount = categories.length - 5;
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

      int totalLearning = 0;
      int featuredLearning = 0;
      for (final col in ['learning_content', 'learning', 'financial_learning', 'learnings', 'articles', 'learning_contents']) {
        try {
          final learnSnap = await fs.collection(col).get().timeout(const Duration(seconds: 4));
          if (learnSnap.docs.isNotEmpty) {
            totalLearning = learnSnap.docs.length;
            featuredLearning = learnSnap.docs.where((d) => (d.data()['isFeatured'] == true || d.data()['featured'] == true)).length;
            break;
          }
        } catch (_) {}
      }

      final faqsSnap = await fs.collection(_faqsCollection).get().timeout(const Duration(seconds: 10));
      final int totalFaqs = faqsSnap.docs.length;

      int pendingInquiries = 0;
      int totalInquiries = 0;
      final List<ContactMessageModel> recentInquiries = [];

      try {
        final contactsSnap = await fs.collection(_contactsCollection).get().timeout(const Duration(seconds: 5));
        totalInquiries = contactsSnap.docs.length;
        final allInquiries = contactsSnap.docs
            .map((doc) => ContactMessageModel.fromMap(doc.data(), docId: doc.id))
            .toList();
        allInquiries.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        recentInquiries.addAll(allInquiries.take(4));
        pendingInquiries = allInquiries.where((c) => c.status == ContactStatus.newMsg).length;
      } catch (e) {
        debugPrint("DashboardService: Error fetching contacts: $e");
      }

      return DashboardStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        blockedUsers: blockedUsers,
        totalPlatformBalance: totalPlatformBalance,
        recentUsers: recentUsers,
        weeklyRegistrations: weeklyRegistrations,
        usersByRole: usersByRole,
        totalCategories: totalCategories,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        categorySlices: categorySlices,
        totalLearning: totalLearning,
        featuredLearning: featuredLearning,
        totalFaqs: totalFaqs,
        pendingInquiries: pendingInquiries,
        totalInquiries: totalInquiries,
        recentInquiries: recentInquiries,
        isFirestoreConnected: true,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint("DashboardService.fetchDashboardDataOnline error: $e");
      return DashboardStats(isFirestoreConnected: false);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(_usersCollection).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategoriesStream() {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(_categoriesCollection).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLearningStream() {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(_learningCollection).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFaqsStream() {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(_faqsCollection).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getContactStream() {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(_contactsCollection).snapshots();
  }
}

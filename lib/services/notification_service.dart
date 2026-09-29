import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  static const String collectionName = 'notifications';
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("NotificationService: Firestore unavailable: $e");
    }
    return null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream() {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(collectionName).snapshots();
  }

  Future<List<NotificationModel>> fetchNotificationsOnce() async {
    final fs = firestore;
    if (fs == null) return [];

    try {
      final snapshot = await fs.collection(collectionName).get();
      final list = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), docId: doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint("NotificationService.fetchNotificationsOnce error: $e");
      return [];
    }
  }

  Future<bool> createNotification(NotificationModel notification) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      final docRef = notification.id.isNotEmpty
          ? fs.collection(collectionName).doc(notification.id)
          : fs.collection(collectionName).doc();

      await docRef.set({
        ...notification.toMap(),
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("NotificationService.createNotification error: $e");
      return false;
    }
  }

  Future<bool> markAsRead(String id) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(collectionName).doc(id).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("NotificationService.markAsRead error: $e");
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      final unread = await fs.collection(collectionName).where('isRead', isEqualTo: false).get();
      final batch = fs.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("NotificationService.markAllAsRead error: $e");
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(collectionName).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("NotificationService.deleteNotification error: $e");
      return false;
    }
  }

  Future<bool> clearAllNotifications() async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      final all = await fs.collection(collectionName).get();
      final batch = fs.batch();
      for (final doc in all.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("NotificationService.clearAllNotifications error: $e");
      return false;
    }
  }

  Future<int> seedSampleNotificationsIfEmpty() async {
    final fs = firestore;
    if (fs == null) return 0;

    try {
      final existing = await fs.collection(collectionName).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return 0;
      }

      final samples = [
        {
          'title': 'New User Registered: Marcus Vance',
          'message': 'Marcus Vance (marcus.vance@workhub.co) created a verified PennyPal account.',
          'type': 'user_registered',
          'target': 'admin',
          'isRead': false,
          'createdAt': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
        },
        {
          'title': 'New Customer Inquiry from Sarah Jenkins',
          'message': 'Subject: "Receipt Scanning Currency Support" - Requires administrator response.',
          'type': 'contact_message',
          'target': 'admin',
          'isRead': false,
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'title': '5-Star Review Received: Elena Rostova',
          'message': 'Elena submitted a 5-star rating: "PennyPal has completely revolutionized my monthly budgeting!"',
          'type': 'feedback_received',
          'target': 'admin',
          'isRead': true,
          'createdAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        },
        {
          'title': 'Academy Content Live: Smart Budgeting 101',
          'message': 'Published to User App: "Mastering Zero-Based Budgeting in PennyPal Mobile".',
          'type': 'learning_published',
          'target': 'all',
          'isRead': true,
          'createdAt': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        },
        {
          'title': 'Security Audit & Compliance Cleared',
          'message': 'System database backup and encryption key rotation successfully validated.',
          'type': 'system_alert',
          'target': 'admin',
          'isRead': true,
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];

      for (final s in samples) {
        final docRef = fs.collection(collectionName).doc();
        await docRef.set({
          ...s,
          'id': docRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return samples.length;
    } catch (e) {
      debugPrint("NotificationService.seedSampleNotificationsIfEmpty error: $e");
      return 0;
    }
  }
}

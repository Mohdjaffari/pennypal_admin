import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class FeedbackService {
  static const String collectionName = 'feedback';
  static const String fallbackCollection = 'feedbacks';
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("FeedbackService: Firestore unavailable: $e");
    }
    return null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFeedbacksStream({String? filter}) {
    final fs = firestore;
    if (fs == null) return const Stream.empty();

    return fs.collection(collectionName).snapshots();
  }

  Future<List<FeedbackModel>> fetchFeedbacksOnce() async {
    final fs = firestore;
    if (fs == null) return [];

    try {
      final snapshot = await fs.collection(collectionName).get();
      final list = snapshot.docs.map((doc) => FeedbackModel.fromMap(doc.data(), docId: doc.id)).toList();

      try {
        final fallbackSnap = await fs.collection(fallbackCollection).get();
        for (final doc in fallbackSnap.docs) {
          if (!list.any((f) => f.id == doc.id)) {
            list.add(FeedbackModel.fromMap(doc.data(), docId: doc.id));
          }
        }
      } catch (_) {}

      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    } catch (e) {
      debugPrint("FeedbackService.fetchFeedbacksOnce error: $e");
      return [];
    }
  }

  Future<bool> toggleFeedbackReviewed(String feedbackId, bool isReviewed) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      final docRef = fs.collection(collectionName).doc(feedbackId);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.update({
          'isReviewed': isReviewed,
          'reviewedAt': isReviewed ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await fs.collection(fallbackCollection).doc(feedbackId).update({
          'isReviewed': isReviewed,
          'reviewedAt': isReviewed ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      debugPrint("FeedbackService.toggleFeedbackReviewed error: $e");
      return false;
    }
  }

  Future<bool> deleteFeedback(String feedbackId) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(collectionName).doc(feedbackId).delete().catchError((_) {});
      await fs.collection(fallbackCollection).doc(feedbackId).delete().catchError((_) {});
      return true;
    } catch (e) {
      debugPrint("FeedbackService.deleteFeedback error: $e");
      return false;
    }
  }

  Future<bool> createFeedback(FeedbackModel model) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      final docRef = model.id.isNotEmpty
          ? fs.collection(collectionName).doc(model.id)
          : fs.collection(collectionName).doc();

      await docRef.set({
        ...model.toMap(),
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await NotificationService.instance.createNotification(
          NotificationModel(
            id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
            title: '${model.rating}★ Review from ${model.userName}',
            message: '${model.feedbackType}: "${model.comments.length > 70 ? '${model.comments.substring(0, 70)}...' : model.comments}"',
            type: NotificationType.feedbackReceived,
            target: NotificationTarget.admin,
            createdAt: DateTime.now(),
            referenceId: docRef.id,
            metadata: {
              'userName': model.userName,
              'userEmail': model.userEmail,
              'rating': model.rating,
              'feedbackType': model.feedbackType,
            },
          ),
        );
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint("FeedbackService.createFeedback error: $e");
      return false;
    }
  }

  Future<int> seedSampleFeedbacksIfEmpty() async {
    final fs = firestore;
    if (fs == null) return 0;

    try {
      final existing = await fs.collection(collectionName).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return 0;
      }

      final samples = [
        {
          'userName': 'Elena Rostova',
          'userEmail': 'elena.rostova@gmail.com',
          'rating': 5,
          'feedbackType': 'App Experience',
          'comments': 'PennyPal has completely revolutionized how I manage my family monthly budget. The visual analytics and expense breakdown are clean, intuitive, and responsive!',
          'isReviewed': true,
          'submittedAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        },
        {
          'userName': 'Marcus Vance',
          'userEmail': 'marcus.vance@workhub.co',
          'rating': 5,
          'feedbackType': 'Feature Request',
          'comments': 'Would love to see multi-currency wallet support so I can track both USD and EUR accounts simultaneously during remote consulting work.',
          'isReviewed': false,
          'submittedAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        },
        {
          'userName': 'Sophia Martinez',
          'userEmail': 'sophia.m@cloudcorp.org',
          'rating': 4,
          'feedbackType': 'App Experience',
          'comments': 'Smooth animations and very clean UI! It would be even better if the dark mode contrast was slightly higher on OLED screens.',
          'isReviewed': false,
          'submittedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'userName': 'Liam O\'Connor',
          'userEmail': 'liam.oc@dublin-ventures.ie',
          'rating': 3,
          'feedbackType': 'Bug Report',
          'comments': 'Occasional delay when syncing categories after adding a new custom icon. Refreshing usually fixes it, but please look into websocket reconnect.',
          'isReviewed': true,
          'submittedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'userName': 'Aria Patel',
          'userEmail': 'aria.patel@designstudio.in',
          'rating': 5,
          'feedbackType': 'General',
          'comments': 'Hands down the most beautiful personal finance app I have used in 2025. Keep up the brilliant work team PennyPal!',
          'isReviewed': true,
          'submittedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
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
      debugPrint("FeedbackService.seedSampleFeedbacksIfEmpty error: $e");
      return 0;
    }
  }
}

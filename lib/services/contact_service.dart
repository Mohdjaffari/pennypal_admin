import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class ContactService {
  static const String collectionName = 'contact_messages';
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("ContactService: Firestore unavailable: $e");
    }
    return null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getContactMessagesStream({String? statusFilter}) {
    final fs = firestore;
    if (fs == null) return const Stream.empty();

    return fs.collection(collectionName).snapshots();
  }

  Future<List<ContactMessageModel>> fetchContactMessagesOnce() async {
    final fs = firestore;
    if (fs == null) return [];

    try {
      final snapshot = await fs.collection(collectionName).get();
      final list = snapshot.docs.map((doc) => ContactMessageModel.fromMap(doc.data(), docId: doc.id)).toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    } catch (e) {
      debugPrint("ContactService.fetchContactMessagesOnce error: $e");
      return [];
    }
  }

  Future<bool> updateStatus(String messageId, ContactStatus status) async {
    final fs = firestore;
    if (fs == null) return false;

    String statusStr = 'newMsg';
    if (status == ContactStatus.resolved) statusStr = 'resolved';
    if (status == ContactStatus.inProgress) statusStr = 'inProgress';

    try {
      await fs.collection(collectionName).doc(messageId).update({
        'status': statusStr,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("ContactService.updateStatus error: $e");
      return false;
    }
  }

  Future<bool> replyToMessage(String messageId, String replyText, {String? adminEmail}) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(collectionName).doc(messageId).update({
        'adminReply': replyText,
        'repliedAt': FieldValue.serverTimestamp(),
        'repliedBy': adminEmail ?? 'PennyPal Support Admin',
        'status': 'resolved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("ContactService.replyToMessage error: $e");
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(collectionName).doc(messageId).delete();
      return true;
    } catch (e) {
      debugPrint("ContactService.deleteMessage error: $e");
      return false;
    }
  }

  Future<bool> createContactMessage(ContactMessageModel model) async {
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
            title: 'New Customer Inquiry: ${model.subject}',
            message: 'Inquiry from ${model.senderName} (${model.senderEmail}): "${model.message.length > 70 ? '${model.message.substring(0, 70)}...' : model.message}"',
            type: NotificationType.contactMessage,
            target: NotificationTarget.admin,
            createdAt: DateTime.now(),
            referenceId: docRef.id,
            metadata: {
              'senderName': model.senderName,
              'senderEmail': model.senderEmail,
              'subject': model.subject,
            },
          ),
        );
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint("ContactService.createContactMessage error: $e");
      return false;
    }
  }

  Future<int> seedSampleMessagesIfEmpty() async {
    final fs = firestore;
    if (fs == null) return 0;

    try {
      final existing = await fs.collection(collectionName).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return 0;
      }

      final samples = [
        {
          'senderName': 'Sarah Jenkins',
          'senderEmail': 'sarah.jenkins@example.com',
          'phone': '+1 (555) 234-5678',
          'subject': 'Receipt Scanning Currency Support',
          'message': 'Hi PennyPal team! Does the receipt scanner support Euro and GBP conversions automatically when traveling abroad? Loving the app so far!',
          'status': 'newMsg',
          'submittedAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        },
        {
          'senderName': 'Michael Chen',
          'senderEmail': 'm.chen92@techmail.io',
          'phone': '+1 (555) 876-5432',
          'subject': 'Exporting Yearly Tax Reports to CSV',
          'message': 'Hello, I need to export all my 2025 business categorized expenses for my accountant. Can you clarify how to filter multiple categories at once?',
          'status': 'inProgress',
          'submittedAt': DateTime.now().subtract(const Duration(hours: 18)).toIso8601String(),
        },
        {
          'senderName': 'Amara Okoye',
          'senderEmail': 'amara.o@finvision.net',
          'phone': '+44 20 7946 0912',
          'subject': 'Biometric Login Not Prompting on iOS',
          'message': 'Since the latest update, Face ID fails to pop up on app resume. I have to re-enter my PIN every time. Is this an ongoing bug?',
          'status': 'resolved',
          'adminReply': 'Hello Amara, thank you for reaching out! We released patch v1.4.2 yesterday resolving FaceID permission caching. Please update your PennyPal app from the App Store and re-enable Biometrics in Settings.',
          'repliedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'submittedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'senderName': 'David Rossi',
          'senderEmail': 'd.rossi@milano-design.it',
          'phone': '+39 02 6942 1100',
          'subject': 'Budget Alert Notification Thresholds',
          'message': 'Is it possible to customize the notification threshold for monthly budgets to 75% instead of 90%? I want earlier warnings before overspending.',
          'status': 'newMsg',
          'submittedAt': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
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
      debugPrint("ContactService.seedSampleMessagesIfEmpty error: $e");
      return 0;
    }
  }
}

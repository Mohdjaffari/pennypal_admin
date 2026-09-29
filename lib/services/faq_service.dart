import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/faq_model.dart';

class FaqService {
  FirebaseFirestore? _firestoreInstance;
  static const String _collectionName = "faqs";

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("FaqService: Firestore unavailable: $e");
    }
    return null;
  }

  Future<FaqModel?> addFaqOnline(FaqModel faq) async {
    final fs = firestore;
    final generatedId = (faq.id.isNotEmpty && !faq.id.startsWith('temp'))
        ? faq.id
        : 'FAQ-${DateTime.now().millisecondsSinceEpoch}';

    final newFaq = faq.copyWith(
      id: generatedId,
      createdBy: faq.createdBy ?? 'admin',
    );

    if (fs == null) {
      return newFaq;
    }

    try {
      final docRef = fs.collection(_collectionName).doc(generatedId);
      await docRef.set(newFaq.toMap()).timeout(const Duration(seconds: 10));
      return newFaq;
    } catch (e) {
      debugPrint("FaqService.addFaqOnline error: $e");
      rethrow;
    }
  }

  Future<bool> updateFaqOnline(String id, Map<String, dynamic> updateData) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      updateData['updatedAt'] = DateTime.now().toIso8601String();
      await fs.collection(_collectionName).doc(id).update(updateData).timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("FaqService.updateFaqOnline error: $e");
      rethrow;
    }
  }

  Future<bool> deleteFaqOnline(String id) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(_collectionName).doc(id).delete().timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("FaqService.deleteFaqOnline error: $e");
      rethrow;
    }
  }

  Future<List<FaqModel>> fetchFaqsOnline(String category) async {
    final fs = firestore;
    if (fs == null) return [];

    try {
      Query<Map<String, dynamic>> query = fs.collection(_collectionName);

      if (category.isNotEmpty && category.toLowerCase() != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 10));
      return snapshot.docs.map((doc) {
        return FaqModel.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint("FaqService.fetchFaqsOnline error: $e");
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFaqsStream([String category = 'All']) {
    final fs = firestore;
    if (fs == null) {
      return const Stream.empty();
    }

    try {
      Query<Map<String, dynamic>> query = fs.collection(_collectionName);

      if (category.isNotEmpty && category.toLowerCase() != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      return query.snapshots();
    } catch (e) {
      debugPrint("FaqService.getFaqsStream error: $e");
      return const Stream.empty();
    }
  }

  Future<bool> toggleFaqStatusOnline(String id, bool isActive) async {
    return updateFaqOnline(id, {'isActive': isActive});
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/learning_model.dart';

class LearningService {
  FirebaseFirestore? _firestoreInstance;

  static const String _cloudName = "dv3emlteu";
  static const String _uploadPreset = "pennyPal";
  static const String _collectionName = "learning_content";

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("LearningService: Firestore unavailable: $e");
    }
    return null;
  }

  Future<String> uploadBannerImage(Uint8List imageBytes, String fileName) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: fileName.isNotEmpty ? fileName : 'learning_banner.jpg',
          ),
        );

      final response = await request.send().timeout(const Duration(seconds: 40));
      final responseData = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonMap['secure_url'] != null) {
        return jsonMap['secure_url'].toString();
      } else {
        debugPrint("LearningService: Cloudinary upload failed [${response.statusCode}]");
        return '';
      }
    } catch (e) {
      debugPrint("LearningService: Cloudinary exception: $e");
      return '';
    }
  }

  Future<LearningContentModel?> addLearningOnline(LearningContentModel item) async {
    final fs = firestore;
    final generatedId = (item.id.isNotEmpty && !item.id.startsWith('temp'))
        ? item.id
        : 'LRN-${DateTime.now().millisecondsSinceEpoch}';

    final newItem = item.copyWith(
      id: generatedId,
      createdBy: item.createdBy ?? 'admin',
    );

    if (fs == null) {
      return newItem;
    }

    try {
      final docRef = fs.collection(_collectionName).doc(generatedId);
      await docRef.set(newItem.toMap()).timeout(const Duration(seconds: 10));
      return newItem;
    } catch (e) {
      debugPrint("LearningService.addLearningOnline error: $e");
      rethrow;
    }
  }

  Future<bool> updateLearningOnline(String id, Map<String, dynamic> updateData) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      updateData['updatedAt'] = DateTime.now().toIso8601String();
      await fs.collection(_collectionName).doc(id).update(updateData).timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("LearningService.updateLearningOnline error: $e");
      rethrow;
    }
  }

  Future<bool> deleteLearningOnline(String id) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(_collectionName).doc(id).delete().timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("LearningService.deleteLearningOnline error: $e");
      rethrow;
    }
  }

  static const List<String> _fallbackCollections = [
    "learning",
    "financial_learning",
    "learnings",
    "articles",
  ];

  Future<List<LearningContentModel>> fetchLearningOnline([String category = 'All']) async {
    final fs = firestore;
    if (fs == null) return [];

    try {
      final List<LearningContentModel> results = [];
      final primarySnap = await fs.collection(_collectionName).get().timeout(const Duration(seconds: 10));
      for (final doc in primarySnap.docs) {
        try {
          results.add(LearningContentModel.fromMap(doc.data(), docId: doc.id));
        } catch (e) {
          debugPrint("Error parsing learning doc ${doc.id}: $e");
        }
      }

      // If primary collection is empty, check fallback collections
      if (results.isEmpty) {
        for (final col in _fallbackCollections) {
          try {
            final fbSnap = await fs.collection(col).get().timeout(const Duration(seconds: 5));
            if (fbSnap.docs.isNotEmpty) {
              for (final doc in fbSnap.docs) {
                if (!results.any((r) => r.id == doc.id)) {
                  try {
                    results.add(LearningContentModel.fromMap(doc.data(), docId: doc.id));
                  } catch (e) {
                    debugPrint("Error parsing fallback learning doc ${doc.id}: $e");
                  }
                }
              }
              if (results.isNotEmpty) break;
            }
          } catch (_) {}
        }
      }

      if (category.isNotEmpty && category.toLowerCase() != 'all') {
        return results.where((item) => item.category.trim().toLowerCase() == category.toLowerCase()).toList();
      }

      return results;
    } catch (e) {
      debugPrint("LearningService.fetchLearningOnline error: $e");
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLearningStream([String category = 'All']) {
    final fs = firestore;
    if (fs == null) {
      return const Stream.empty();
    }

    try {
      // Stream the full collection so case-insensitive filtering can be done client-side
      return fs.collection(_collectionName).snapshots();
    } catch (e) {
      debugPrint("LearningService.getLearningStream error: $e");
      return const Stream.empty();
    }
  }

  Future<bool> toggleFeaturedOnline(String id, bool isFeatured) async {
    return updateLearningOnline(id, {'isFeatured': isFeatured});
  }
}

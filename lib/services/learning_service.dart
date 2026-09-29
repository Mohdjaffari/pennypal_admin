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

  static const List<String> candidateCollections = [
    "learning_content",
    "learning",
    "financial_learning",
    "learnings",
    "articles",
    "learning_contents",
  ];

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
      final targetCollection = item.sourceCollection.isNotEmpty
          ? item.sourceCollection
          : _collectionName;
      final docRef = fs.collection(targetCollection).doc(generatedId);
      await docRef.set(newItem.toMap()).timeout(const Duration(seconds: 10));
      return newItem;
    } catch (e) {
      debugPrint("LearningService.addLearningOnline error: $e");
      rethrow;
    }
  }

  Future<bool> updateLearningOnline(
    String id,
    Map<String, dynamic> updateData, {
    String? sourceCollection,
  }) async {
    final fs = firestore;
    if (fs == null) return false;

    updateData['updatedAt'] = DateTime.now().toIso8601String();

    final collectionsToTry = [
      if (sourceCollection != null && sourceCollection.isNotEmpty) sourceCollection,
      ...candidateCollections,
    ];

    bool updated = false;
    for (final col in collectionsToTry) {
      try {
        final docRef = fs.collection(col).doc(id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          await docRef.update(updateData).timeout(const Duration(seconds: 10));
          updated = true;
          break;
        }
      } catch (_) {}
    }

    if (!updated) {
      // Fallback: update in default collection
      try {
        await fs.collection(_collectionName).doc(id).update(updateData).timeout(const Duration(seconds: 10));
        return true;
      } catch (e) {
        debugPrint("LearningService.updateLearningOnline fallback error: $e");
        return false;
      }
    }

    return updated;
  }

  Future<bool> deleteLearningOnline(String id, {String? sourceCollection}) async {
    final fs = firestore;
    if (fs == null) return false;

    final collectionsToTry = [
      if (sourceCollection != null && sourceCollection.isNotEmpty) sourceCollection,
      ...candidateCollections,
    ];

    bool deleted = false;
    for (final col in collectionsToTry) {
      try {
        final docRef = fs.collection(col).doc(id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          await docRef.delete().timeout(const Duration(seconds: 10));
          deleted = true;
        }
      } catch (_) {}
    }

    return deleted;
  }

  /// Real-time multi-collection stream that continuously merges and deduplicates
  /// all learning content across candidate collections in Firestore.
  Stream<List<LearningContentModel>> getCombinedLearningStream() {
    final fs = firestore;
    if (fs == null) return Stream.value([]);

    late StreamController<List<LearningContentModel>> controller;
    final Map<String, List<LearningContentModel>> collectionCache = {};
    final List<StreamSubscription> subscriptions = [];

    void emitMerged() {
      if (controller.isClosed) return;
      final Map<String, LearningContentModel> merged = {};

      for (final col in candidateCollections) {
        final list = collectionCache[col] ?? [];
        for (final item in list) {
          if (!merged.containsKey(item.id)) {
            merged[item.id] = item;
          }
        }
      }

      final results = merged.values.toList();
      results.sort((a, b) {
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }
        return b.publishedDate.compareTo(a.publishedDate);
      });

      controller.add(results);
    }

    controller = StreamController<List<LearningContentModel>>.broadcast(
      onListen: () {
        for (final col in candidateCollections) {
          try {
            final sub = fs.collection(col).snapshots().listen(
              (snap) {
                final List<LearningContentModel> items = [];
                for (final doc in snap.docs) {
                  try {
                    items.add(LearningContentModel.fromMap(
                      doc.data(),
                      docId: doc.id,
                      sourceCollection: col,
                    ));
                  } catch (e) {
                    debugPrint("Error parsing learning doc ${doc.id} in $col: $e");
                  }
                }
                collectionCache[col] = items;
                emitMerged();
              },
              onError: (e) {
                debugPrint("Notice: Learning collection $col listener: $e");
              },
            );
            subscriptions.add(sub);
          } catch (e) {
            debugPrint("Failed to attach listener for $col: $e");
          }
        }
      },
      onCancel: () {
        for (final sub in subscriptions) {
          sub.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// One-time fetch with fallback across candidate collections
  Future<List<LearningContentModel>> fetchLearningOnline([String category = 'All']) async {
    final fs = firestore;
    if (fs == null) return [];

    try {
      final Map<String, LearningContentModel> merged = {};
      for (final col in candidateCollections) {
        try {
          final snap = await fs.collection(col).get().timeout(const Duration(seconds: 6));
          for (final doc in snap.docs) {
            if (!merged.containsKey(doc.id)) {
              try {
                merged[doc.id] = LearningContentModel.fromMap(
                  doc.data(),
                  docId: doc.id,
                  sourceCollection: col,
                );
              } catch (e) {
                debugPrint("Error parsing doc ${doc.id} in $col: $e");
              }
            }
          }
        } catch (_) {}
      }

      var results = merged.values.toList();
      if (category.isNotEmpty && category.toLowerCase() != 'all') {
        results = results
            .where((item) => item.category.trim().toLowerCase() == category.toLowerCase())
            .toList();
      }

      results.sort((a, b) {
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }
        return b.publishedDate.compareTo(a.publishedDate);
      });

      return results;
    } catch (e) {
      debugPrint("LearningService.fetchLearningOnline error: $e");
      return [];
    }
  }

  /// Legacy stream method for backwards compatibility
  Stream<QuerySnapshot<Map<String, dynamic>>> getLearningStream([String category = 'All']) {
    final fs = firestore;
    if (fs == null) {
      return const Stream.empty();
    }
    try {
      return fs.collection(_collectionName).snapshots();
    } catch (e) {
      debugPrint("LearningService.getLearningStream error: $e");
      return const Stream.empty();
    }
  }

  Future<bool> toggleFeaturedOnline(String id, bool isFeatured, {String? sourceCollection}) async {
    return updateLearningOnline(id, {'isFeatured': isFeatured}, sourceCollection: sourceCollection);
  }
}

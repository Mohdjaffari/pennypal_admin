import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';

class CategoryService {
  FirebaseFirestore? _firestoreInstance;

  static const String _cloudName = "dv3emlteu";
  static const String _uploadPreset = "pennyPal";
  static const String _categoriesCollection = "categories";

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("CategoryService: Firestore unavailable: $e");
    }
    return null;
  }

  Future<String> uploadIcon(Uint8List imageBytes, String fileName) async {
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
            filename: fileName.isNotEmpty ? fileName : 'category_icon.png',
          ),
        );

      final response = await request.send().timeout(const Duration(seconds: 40));
      final responseData = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonMap['secure_url'] != null) {
        return jsonMap['secure_url'].toString();
      } else {
        debugPrint("CategoryService: Cloudinary upload failed [${response.statusCode}]");
        return '';
      }
    } catch (e) {
      debugPrint("CategoryService: Cloudinary exception: $e");
      return '';
    }
  }

  Future<CategoryModel?> addCategoryOnline(CategoryModel category) async {
    final fs = firestore;
    final generatedId = (category.id != null && category.id!.isNotEmpty)
        ? category.id!
        : 'CAT-${DateTime.now().millisecondsSinceEpoch}';

    final newCategory = category.copyWith(
      id: generatedId,
      isSynced: fs != null ? 1 : 0,
      createdBy: category.createdBy ?? 'admin',
      isDefault: true,
    );

    if (fs == null) {
      return newCategory;
    }

    try {
      final docRef = fs.collection(_categoriesCollection).doc(generatedId);
      await docRef.set(newCategory.toMap()).timeout(const Duration(seconds: 10));
      return newCategory;
    } catch (e) {
      debugPrint("CategoryService.addCategoryOnline error: $e");
      rethrow;
    }
  }

  Future<List<CategoryModel>> fetchCategoriesOnline(String type) async {
    final fs = firestore;
    if (fs == null) return [];

    try {
      Query<Map<String, dynamic>> query = fs.collection(_categoriesCollection);

      if (type.isNotEmpty && type.toLowerCase() != 'all') {
        query = query.where('categoryType', isEqualTo: type.toLowerCase());
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      debugPrint("CategoryService.fetchCategoriesOnline error: $e");
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategoriesStream([String type = 'all']) {
    final fs = firestore;
    if (fs == null) {
      return const Stream.empty();
    }

    try {
      final collection = fs.collection(_categoriesCollection);
      if (type.isEmpty || type.toLowerCase() == 'all') {
        return collection.snapshots();
      }
      return collection
          .where('categoryType', isEqualTo: type.toLowerCase())
          .snapshots();
    } catch (e) {
      debugPrint("CategoryService.getCategoriesStream error: $e");
      return const Stream.empty();
    }
  }

  Future<bool> toggleVisibilityOnline(String id, bool isVisible) async {
    return updateCategory(id, {'isVisibleToUser': isVisible});
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> updateData) async {
    final fs = firestore;
    if (fs == null) return true;

    try {
      await fs
          .collection(_categoriesCollection)
          .doc(id)
          .update(updateData)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("CategoryService.updateCategory error: $e");
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    final fs = firestore;
    if (fs == null) return true;

    try {
      await fs
          .collection(_categoriesCollection)
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("CategoryService.deleteCategory error: $e");
      return false;
    }
  }
}

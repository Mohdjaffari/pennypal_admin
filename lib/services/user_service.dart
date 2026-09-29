import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  FirebaseFirestore? _firestoreInstance;
  static const String _collectionName = "users";

  static const String _cloudName = "dv3emlteu";
  static const String _uploadPreset = "pennyPal";

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("UserService: Firestore unavailable: $e");
    }
    return null;
  }

  Future<String> uploadAvatar(Uint8List imageBytes, String fileName) async {
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
            filename: fileName.isNotEmpty ? fileName : 'user_avatar.jpg',
          ),
        );

      final response = await request.send().timeout(const Duration(seconds: 40));
      final responseData = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonMap['secure_url'] != null) {
        return jsonMap['secure_url'].toString();
      } else {
        debugPrint("UserService: Cloudinary upload failed [${response.statusCode}]");
        return '';
      }
    } catch (e) {
      debugPrint("UserService: Cloudinary exception: $e");
      return '';
    }
  }

  Future<UserModel?> addUserOnline(UserModel user) async {
    final fs = firestore;
    final generatedId = (user.id.isNotEmpty && !user.id.startsWith('temp'))
        ? user.id
        : 'USR-${DateTime.now().millisecondsSinceEpoch}';

    final newUser = user.copyWith(id: generatedId);

    if (fs == null) {
      return newUser;
    }

    try {
      final docRef = fs.collection(_collectionName).doc(generatedId);
      await docRef.set(newUser.toMap()).timeout(const Duration(seconds: 10));
      return newUser;
    } catch (e) {
      debugPrint("UserService.addUserOnline error: $e");
      rethrow;
    }
  }

  Future<bool> updateUserOnline(String uid, Map<String, dynamic> updateData) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      updateData['updatedAt'] = DateTime.now().toIso8601String();
      await fs.collection(_collectionName).doc(uid).update(updateData).timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("UserService.updateUserOnline error: $e");
      rethrow;
    }
  }

  Future<bool> toggleBlockUserOnline(String uid, bool currentBlockedStatus) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      final newStatus = !currentBlockedStatus;
      await fs.collection(_collectionName).doc(uid).update({
        'isBlocked': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("UserService.toggleBlockUserOnline error: $e");
      rethrow;
    }
  }

  Future<bool> deleteUserOnline(String uid) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(_collectionName).doc(uid).delete().timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint("UserService.deleteUserOnline error: $e");
      rethrow;
    }
  }

  Future<List<UserModel>> fetchUsersOnline() async {
    final fs = firestore;
    if (fs == null) return [];

    try {
      final snapshot = await fs.collection(_collectionName).get().timeout(const Duration(seconds: 10));
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint("UserService.fetchUsersOnline error: $e");
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    final fs = firestore;
    if (fs == null) {
      return const Stream.empty();
    }

    try {
      return fs.collection(_collectionName).snapshots();
    } catch (e) {
      debugPrint("UserService.getUsersStream error: $e");
      return const Stream.empty();
    }
  }
}

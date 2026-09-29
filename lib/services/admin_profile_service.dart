import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/admin_profile_model.dart';
import '../models/admin_settings_model.dart';

class AdminProfileService {
  static const String adminsCollection = 'admins';
  static const String settingsCollection = 'admin_settings';
  static const String globalSettingsDoc = 'global_config';

  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance ??= FirebaseFirestore.instance;
        return _firestoreInstance;
      }
    } catch (e) {
      debugPrint("AdminProfileService: Firestore unavailable: $e");
    }
    return null;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getAdminProfileStream(String adminId) {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(adminsCollection).doc(adminId).snapshots();
  }

  Future<bool> saveAdminProfile(AdminProfileModel profile) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(adminsCollection).doc(profile.id).set(
        profile.toMap(),
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint("AdminProfileService.saveAdminProfile error: $e");
      return false;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getAdminSettingsStream() {
    final fs = firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection(settingsCollection).doc(globalSettingsDoc).snapshots();
  }

  Future<bool> saveAdminSettings(AdminSettingsModel settings) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      await fs.collection(settingsCollection).doc(globalSettingsDoc).set(
        settings.toMap(),
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint("AdminProfileService.saveAdminSettings error: $e");
      return false;
    }
  }
}

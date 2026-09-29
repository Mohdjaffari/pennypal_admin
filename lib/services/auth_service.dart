import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class AuthService {
  // ── SINGLETON ──
  static final AuthService instance = AuthService();

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint("FirebaseAuth note: $e");
    }
    return null;
  }

  FirebaseFirestore? get _database {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint("FirebaseFirestore note: $e");
    }
    return null;
  }

  // ── Cached user ──
  UserModel? _cachedUser;
  UserModel? get cachedUser => _cachedUser;

  bool get isLoggedIn =>
      _cachedUser != null && _auth != null && _auth!.currentUser != null;

  String get userName => _cachedUser?.name ?? 'Admin';

  // ── Check if role is authorized as administrator ──
  static bool isRoleAdmin(String role) {
    final r = role.trim().toLowerCase();
    return r == 'admin' ||
        r == 'super administrator' ||
        r == 'superadmin' ||
        r == 'administrator' ||
        r.contains('admin');
  }

  // ── Restore session on app start with role verification ──
  Future<bool> init() async {
    final auth = _auth;
    final db = _database;
    final fbUser = auth?.currentUser;

    if (fbUser != null && db != null) {
      try {
        final doc = await db.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final userModel = UserModel.fromMap(doc.data()!, docId: doc.id);
          if (isRoleAdmin(userModel.role)) {
            _cachedUser = userModel;
            return true;
          }
        }

        final adminDoc = await db.collection('admins').doc(fbUser.uid).get();
        if (adminDoc.exists && adminDoc.data() != null) {
          _cachedUser = UserModel.fromMap(adminDoc.data()!, docId: adminDoc.id);
          return true;
        }

        // Not an authorized admin: force sign out
        debugPrint("Unauthorized user session detected on init. Signing out.");
        await auth?.signOut();
        _cachedUser = null;
        return false;
      } catch (e) {
        debugPrint("Error restoring session: $e");
        return false;
      }
    }
    return false;
  }

  Future<UserModel?> login(String email, String password) async {
    final auth = _auth;
    final db = _database;

    if (auth == null || db == null) {
      throw 'Firebase is not initialized. Please ensure Firebase is connected.';
    }

    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      final doc = await db.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        await auth.signOut();
        _cachedUser = null;
        throw 'User profile not found in database for UID: $uid. Access denied.';
      }

      final data = doc.data()!;
      final userModel = UserModel.fromMap(data, docId: doc.id);

      if (!isRoleAdmin(userModel.role)) {
        await auth.signOut();
        _cachedUser = null;
        throw 'Access Denied: Your account role is "${userModel.role}". Only users with the "admin" role are permitted to log into the Admin Portal.';
      }

      await db.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      }).catchError((e) {
        debugPrint("Note: unable to update lastLogin timestamp: $e");
      });

      _cachedUser = userModel;
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _getReadableAuthErrorMessage(e);
    } catch (e) {
      rethrow;
    }
  }

  // ── register new admin account in Firebase Auth & Firestore ──
  Future<UserModel?> register(
    String name,
    String email,
    String password, {
    String role = 'admin',
  }) async {
    final auth = _auth;
    final db = _database;

    if (auth == null || db == null) {
      throw 'Firebase is not connected. Cannot register account.';
    }

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userData = UserModel(
        uid: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        joinedDate: DateTime.now(),
      );

      await db.collection('users').doc(cred.user!.uid).set(userData.toMap());

      // Create notification for admin portal
      try {
        await NotificationService.instance.createNotification(
          NotificationModel(
            id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
            title: 'New Account Created: ${userData.name}',
            message: '${userData.name} (${userData.email}) registered a new account on PennyPal.',
            type: NotificationType.userRegistered,
            target: NotificationTarget.admin,
            createdAt: DateTime.now(),
            referenceId: userData.id,
            metadata: {
              'userName': userData.name,
              'userEmail': userData.email,
              'role': userData.role,
            },
          ),
        );
      } catch (_) {}

      _cachedUser = userData;
      return userData;
    } on FirebaseAuthException catch (e) {
      throw _getReadableAuthErrorMessage(e);
    } catch (e) {
      throw 'Registration failed: $e';
    }
  }

  // ── logout ──
  Future<void> logout() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    _cachedUser = null;
  }

  // ── updateUser ──
  Future<void> updateUser(String uid, String name, String email) async {
    final db = _database;
    if (db != null) {
      try {
        await db.collection('users').doc(uid).update({
          'name': name,
          'email': email,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (e) {
        throw e.message ?? 'Failed to update profile.';
      }
    }
    if (_cachedUser != null && _cachedUser!.uid == uid) {
      _cachedUser = _cachedUser!.copyWith(
        name: name,
        email: email,
      );
    }
  }

  // ── changePassword ──
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth?.currentUser;
    if (user == null) {
      throw 'No authenticated admin session found. Please log in again.';
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw 'User email not found for authentication.';
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
      debugPrint("Admin password changed successfully in Firebase Auth.");
    } on FirebaseAuthException catch (e) {
      throw _getReadableAuthErrorMessage(e);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    final cleanEmail = email.trim();

    if (auth == null) {
      throw 'Firebase Authentication is not connected. Please check configuration.';
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw 'Please enter a valid administrator email address.';
    }

    try {
      await auth.sendPasswordResetEmail(email: cleanEmail);
      debugPrint("Password reset email sent successfully to: $cleanEmail");
    } on FirebaseAuthException catch (e) {
      throw _getReadableAuthErrorMessage(e);
    } catch (e) {
      throw 'Failed to send password reset email: $e';
    }
  }

  // ── Human-readable Firebase Auth error translator ──
  String _getReadableAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please verify your credentials.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled by security administrators.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'operation-not-allowed':
        return 'Email/Password authentication is disabled in Firebase Console.';
      case 'too-many-requests':
        return 'Too many attempts. Access is temporarily throttled. Please wait a few moments.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }
}

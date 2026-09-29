import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserController with ChangeNotifier {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Uint8List? _selectedAvatarBytes;
  Uint8List? get selectedAvatarBytes => _selectedAvatarBytes;

  String? _avatarFileName;
  String? get avatarFileName => _avatarFileName;

  final List<UserModel> _users = [];
  List<UserModel> get users => List.unmodifiable(_users);

  /// Picks avatar image bytes using ImagePicker
  Future<void> pickAvatar() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        _selectedAvatarBytes = await pickedFile.readAsBytes();
        _avatarFileName = pickedFile.name;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking avatar: $e");
      _errorMessage = "Unable to select image. Please try again.";
      notifyListeners();
    }
  }

  /// Clears selected avatar
  void clearAvatar() {
    _selectedAvatarBytes = null;
    _avatarFileName = null;
    notifyListeners();
  }

  /// Creates a new User in Firestore database with optional Cloudinary avatar
  Future<bool> createUser({
    required String name,
    required String email,
    required String phone,
    required String role,
    bool isBlocked = false,
    double initialBalance = 0.0,
    String? fallbackAvatarUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String finalAvatarUrl = fallbackAvatarUrl ?? '';

      if (_selectedAvatarBytes != null) {
        final fileName = _avatarFileName ?? 'user_avatar.jpg';
        final uploaded = await _userService.uploadAvatar(_selectedAvatarBytes!, fileName);
        if (uploaded.isNotEmpty) {
          finalAvatarUrl = uploaded;
        }
      }

      final generatedUid = 'USR-${DateTime.now().millisecondsSinceEpoch}';

      final newUser = UserModel(
        id: generatedUid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        role: role,
        isBlocked: isBlocked,
        avatarUrl: finalAvatarUrl,
        joinedDate: DateTime.now(),
        totalBalance: initialBalance,
        totalExpenses: 0.0,
        savings: 0.0,
        totalTransactions: 0,
      );

      final result = await _userService.addUserOnline(newUser);

      if (result != null) {
        _users.insert(0, result);
        clearAvatar();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Failed to provision user in Firebase.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseException catch (e) {
      debugPrint("Firebase error creating user: ${e.code} - ${e.message}");
      if (e.code == 'permission-denied') {
        _errorMessage = "Firestore Permission Denied. Please ensure read/write rules for 'users' are enabled in Firebase Console.";
      } else {
        _errorMessage = e.message ?? e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Error creating user: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing user in Firestore
  Future<bool> updateUser({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String role,
    required bool isBlocked,
    Uint8List? newAvatarBytes,
    String? newAvatarFileName,
    String? existingAvatarUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> updateData = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': role,
        'isBlocked': isBlocked,
      };

      if (newAvatarBytes != null) {
        final fileName = newAvatarFileName ?? 'user_avatar.jpg';
        final uploaded = await _userService.uploadAvatar(newAvatarBytes, fileName);
        if (uploaded.isNotEmpty) {
          updateData['avatarUrl'] = uploaded;
        }
      } else if (existingAvatarUrl != null && existingAvatarUrl.isNotEmpty) {
        updateData['avatarUrl'] = existingAvatarUrl;
      }

      final success = await _userService.updateUserOnline(uid, updateData);
      if (success) {
        final idx = _users.indexWhere((u) => u.id == uid);
        if (idx != -1) {
          _users[idx] = _users[idx].copyWith(
            name: name.trim(),
            email: email.trim().toLowerCase(),
            phone: phone.trim(),
            role: role,
            isBlocked: isBlocked,
            avatarUrl: updateData['avatarUrl'] ?? _users[idx].avatarUrl,
          );
        }
        clearAvatar();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("Error updating user: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggles blocked / active status of a user in Firestore
  Future<bool> toggleBlockUser(String uid, bool currentBlockedStatus) async {
    try {
      final success = await _userService.toggleBlockUserOnline(uid, currentBlockedStatus);
      if (success) {
        final idx = _users.indexWhere((u) => u.id == uid);
        if (idx != -1) {
          _users[idx] = _users[idx].copyWith(isBlocked: !currentBlockedStatus);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint("Error toggling user block status: $e");
      return false;
    }
  }

  /// Deletes a user document from Firestore
  Future<bool> deleteUser(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _userService.deleteUserOnline(uid);
      if (success) {
        _users.removeWhere((u) => u.id == uid);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("Error deleting user: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Returns real-time stream of users from Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    return _userService.getUsersStream();
  }
}

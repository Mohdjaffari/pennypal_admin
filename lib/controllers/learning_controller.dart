import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/learning_model.dart';
import '../models/notification_model.dart';
import '../services/learning_service.dart';
import '../services/notification_service.dart';

class LearningController with ChangeNotifier {
  final LearningService _learningService = LearningService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Uint8List? _selectedImageBytes;
  Uint8List? get selectedImageBytes => _selectedImageBytes;

  String? _imageFileName;
  String? get imageFileName => _imageFileName;

  final List<LearningContentModel> _articles = [];
  List<LearningContentModel> get articles => List.unmodifiable(_articles);

  /// Picks an image file using ImagePicker (works across Web and Mobile)
  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        _selectedImageBytes = await pickedFile.readAsBytes();
        _imageFileName = pickedFile.name;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking learning banner image: $e");
      _errorMessage = "Unable to select image. Please try again.";
      notifyListeners();
    }
  }

  /// Clears currently selected banner image
  void clearImage() {
    _selectedImageBytes = null;
    _imageFileName = null;
    notifyListeners();
  }

  /// Creates a new Learning Article in Firestore with uploaded Cloudinary image
  Future<bool> createLearningArticle({
    required String title,
    required String category,
    required String level,
    required int durationMinutes,
    required String description,
    required String content,
    required bool isFeatured,
    Uint8List? imageBytes,
    String? imageFileName,
    String? fallbackImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String finalImageUrl = fallbackImageUrl ?? '';

      final bytesToUpload = imageBytes ?? _selectedImageBytes;
      if (bytesToUpload != null) {
        final fileName = imageFileName ?? _imageFileName ?? 'learning_banner.jpg';
        final uploadedUrl = await _learningService.uploadBannerImage(bytesToUpload, fileName);
        if (uploadedUrl.isNotEmpty) {
          finalImageUrl = uploadedUrl;
        } else if (finalImageUrl.isEmpty) {
          _errorMessage = "Failed to upload banner image to Cloudinary. Please check your internet connection.";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (finalImageUrl.isEmpty) {
        _errorMessage = "Please select a banner image for the learning article.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newItem = LearningContentModel(
        id: 'LRN-${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        category: category,
        level: level,
        durationMinutes: durationMinutes,
        description: description.trim(),
        content: content.trim(),
        imageUrl: finalImageUrl,
        publishedDate: DateTime.now(),
        isFeatured: isFeatured,
        readCount: 0,
        createdBy: 'admin',
      );

      final result = await _learningService.addLearningOnline(newItem);

      if (result != null) {
        _articles.insert(0, result);
        clearImage();

        try {
          await NotificationService.instance.createNotification(
            NotificationModel(
              id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
              title: 'New Academy Guide: ${result.title}',
              message: 'A new financial learning module "${result.title}" ($category) has been published in PennyPal Academy!',
              type: NotificationType.learningPublished,
              target: NotificationTarget.all,
              createdAt: DateTime.now(),
              referenceId: result.id,
              metadata: {
                'title': result.title,
                'category': result.category,
                'level': result.level,
              },
            ),
          );
        } catch (notifErr) {
          debugPrint("Note: Notification dispatch failed: $notifErr");
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Failed to save article to Firebase.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseException catch (e) {
      debugPrint("Firebase error creating learning article: ${e.code} - ${e.message}");
      if (e.code == 'permission-denied') {
        _errorMessage = "Firestore Permission Denied. Please ensure read/write rules for 'learning_content' are allowed in Firebase Console.";
      } else {
        _errorMessage = e.message ?? e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Error creating learning article: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing learning article with optional new banner image
  Future<bool> updateLearningArticle({
    required String id,
    required String title,
    required String category,
    required String level,
    required int durationMinutes,
    required String description,
    required String content,
    required bool isFeatured,
    Uint8List? newImageBytes,
    String? newImageFileName,
    String? existingImageUrl,
    String? sourceCollection,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> updateData = {
        'title': title.trim(),
        'category': category,
        'level': level,
        'durationMinutes': durationMinutes,
        'description': description.trim(),
        'content': content.trim(),
        'isFeatured': isFeatured,
      };

      if (newImageBytes != null) {
        final fileName = newImageFileName ?? 'learning_banner.jpg';
        final newUrl = await _learningService.uploadBannerImage(newImageBytes, fileName);
        if (newUrl.isNotEmpty) {
          updateData['imageUrl'] = newUrl;
        }
      } else if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
        updateData['imageUrl'] = existingImageUrl;
      }

      final success = await _learningService.updateLearningOnline(
        id,
        updateData,
        sourceCollection: sourceCollection,
      );
      if (success) {
        final idx = _articles.indexWhere((a) => a.id == id);
        if (idx != -1) {
          _articles[idx] = _articles[idx].copyWith(
            title: title.trim(),
            category: category,
            level: level,
            durationMinutes: durationMinutes,
            description: description.trim(),
            content: content.trim(),
            isFeatured: isFeatured,
            imageUrl: updateData['imageUrl'] ?? _articles[idx].imageUrl,
          );
        }
        clearImage();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("Error updating learning article: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a learning article from Firestore
  Future<bool> deleteLearningArticle(String id, {String? sourceCollection}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _learningService.deleteLearningOnline(
        id,
        sourceCollection: sourceCollection,
      );
      if (success) {
        _articles.removeWhere((a) => a.id == id);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("Error deleting learning article: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggles featured status of an article in Firestore
  Future<bool> toggleFeatured(String id, bool currentStatus, {String? sourceCollection}) async {
    try {
      final newStatus = !currentStatus;
      final success = await _learningService.updateLearningOnline(
        id,
        {'isFeatured': newStatus},
        sourceCollection: sourceCollection,
      );
      if (success) {
        final idx = _articles.indexWhere((a) => a.id == id);
        if (idx != -1) {
          _articles[idx] = _articles[idx].copyWith(isFeatured: newStatus);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint("Error toggling featured status: $e");
      return false;
    }
  }

  /// Real-time Firestore stream for learning content (legacy QuerySnapshot)
  Stream<QuerySnapshot<Map<String, dynamic>>> getLearningStream(String category) {
    return _learningService.getLearningStream(category);
  }

  /// Real-time combined multi-collection stream yielding parsed, deduplicated articles
  Stream<List<LearningContentModel>> getCombinedLearningStream([String category = 'All']) {
    return _learningService.getCombinedLearningStream();
  }
}

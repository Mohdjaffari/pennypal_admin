import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryController with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Uint8List? _selectedImageBytes;
  Uint8List? get selectedImageBytes => _selectedImageBytes;

  String? _imageFileName;
  String? get imageFileName => _imageFileName;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => List.unmodifiable(_categories);

  /// Picks an image file using ImagePicker (works on both Web bytes and Mobile)
  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        _selectedImageBytes = await pickedFile.readAsBytes();
        _imageFileName = pickedFile.name;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      _errorMessage = "Unable to select image. Please try again.";
      notifyListeners();
    }
  }

  /// Clears currently selected icon image
  void clearImage() {
    _selectedImageBytes = null;
    _imageFileName = null;
    notifyListeners();
  }

  /// Creates a new Admin Category in Firestore with vector icon
  Future<bool> createAdminCategory({
    required String name,
    required String type,
    String? iconName,
    int? colorValue,
    String? fallbackIconUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String chosenIcon = iconName ??
          (fallbackIconUrl != null && fallbackIconUrl.isNotEmpty
              ? fallbackIconUrl
              : (type.toLowerCase() == 'income'
                  ? 'payments_rounded'
                  : type.toLowerCase() == 'learning'
                      ? 'school_rounded'
                      : 'shopping_bag_rounded'));

      final CategoryModel newCategory = CategoryModel(
        name: name.trim(),
        type: type.toLowerCase(),
        icon: chosenIcon,
        iconName: chosenIcon,
        colorValue: colorValue ??
            (type.toLowerCase() == 'income'
                ? 0xFF10B981
                : type.toLowerCase() == 'learning'
                    ? 0xFF8B5CF6
                    : 0xFFFF3366),
        isDefault: true,
        createdBy: 'admin',
        isSynced: 1,
      );

      final result = await _categoryService.addCategoryOnline(newCategory);

      if (result != null) {
        _categories.insert(0, result);
        clearImage();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Failed to save category to Firebase.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseException catch (e) {
      debugPrint("Firebase error creating admin category: ${e.code} - ${e.message}");
      if (e.code == 'permission-denied') {
        _errorMessage =
            "Firestore Permission Denied. Please enable read/write rules for 'categories' in your Firebase Console (project fluttersfc-a94dd).";
      } else {
        _errorMessage = e.message ?? e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Error creating admin category: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Returns real-time Firestore stream of categories for a given type
  Stream<QuerySnapshot<Map<String, dynamic>>> getCategoriesStream(String type) {
    return _categoryService.getCategoriesStream(type);
  }

  /// Loads categories from Firestore and stores in local state
  Future<void> fetchCategories(String type) async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _categoryService.fetchCategoriesOnline(type);
      _errorMessage = null;
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      _errorMessage = "Failed to fetch categories.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing category in Firestore with optional new icon or image
  Future<bool> updateCategory(
    String id, {
    String? name,
    String? type,
    String? iconName,
    Uint8List? newImageBytes,
    String? newImageFileName,
    String? existingIconUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> updateData = {};

      if (name != null && name.trim().isNotEmpty) {
        updateData['categoryName'] = name.trim();
      }

      if (type != null && type.trim().isNotEmpty) {
        updateData['categoryType'] = type.trim().toLowerCase();
      }

      if (iconName != null && iconName.trim().isNotEmpty) {
        updateData['icon'] = iconName.trim();
        updateData['iconName'] = iconName.trim();
      } else if (newImageBytes != null) {
        final fileName = newImageFileName ?? 'category_icon.png';
        final newIconUrl = await _categoryService.uploadIcon(
          newImageBytes,
          fileName,
        );
        if (newIconUrl.isNotEmpty) {
          updateData['icon'] = newIconUrl;
        }
      } else if (existingIconUrl != null) {
        updateData['icon'] = existingIconUrl;
      }

      if (updateData.isNotEmpty) {
        final success = await _categoryService.updateCategory(id, updateData);
        if (success) {
          final idx = _categories.indexWhere((c) => c.id == id);
          if (idx != -1) {
            _categories[idx] = _categories[idx].copyWith(
              name: name,
              type: type,
              icon: updateData['icon'],
              iconName: updateData['iconName'],
            );
          }
        }
        _isLoading = false;
        notifyListeners();
        return success;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error updating category: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a category by document ID
  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _categoryService.deleteCategory(id);
      if (success) {
        _categories.removeWhere((c) => c.id == id);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("Error deleting category: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/faq_model.dart';
import '../services/faq_service.dart';

class FaqController with ChangeNotifier {
  final FaqService _faqService = FaqService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final List<FaqModel> _faqs = [];
  List<FaqModel> get faqs => List.unmodifiable(_faqs);

  /// Creates a new FAQ item in Firestore
  Future<bool> createFaq({
    required String question,
    required String answer,
    required String category,
    bool isActive = true,
    int displayOrder = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newFaq = FaqModel(
        id: 'FAQ-${DateTime.now().millisecondsSinceEpoch}',
        question: question.trim(),
        answer: answer.trim(),
        category: category,
        isActive: isActive,
        createdAt: DateTime.now(),
        displayOrder: displayOrder,
        createdBy: 'admin',
      );

      final result = await _faqService.addFaqOnline(newFaq);

      if (result != null) {
        _faqs.insert(0, result);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Failed to save FAQ to Firebase.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseException catch (e) {
      debugPrint("Firebase error creating FAQ: ${e.code} - ${e.message}");
      if (e.code == 'permission-denied') {
        _errorMessage = "Firestore Permission Denied. Please ensure read/write rules for 'faqs' are allowed in Firebase Console.";
      } else {
        _errorMessage = e.message ?? e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Error creating FAQ: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing FAQ in Firestore
  Future<bool> updateFaq({
    required String id,
    required String question,
    required String answer,
    required String category,
    required bool isActive,
    int displayOrder = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> updateData = {
        'question': question.trim(),
        'answer': answer.trim(),
        'category': category,
        'isActive': isActive,
        'displayOrder': displayOrder,
      };

      final success = await _faqService.updateFaqOnline(id, updateData);
      if (success) {
        final idx = _faqs.indexWhere((f) => f.id == id);
        if (idx != -1) {
          _faqs[idx] = _faqs[idx].copyWith(
            question: question.trim(),
            answer: answer.trim(),
            category: category,
            isActive: isActive,
            displayOrder: displayOrder,
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("Error updating FAQ: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes an FAQ item from Firestore
  Future<bool> deleteFaq(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _faqService.deleteFaqOnline(id);
      if (success) {
        _faqs.removeWhere((f) => f.id == id);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("Error deleting FAQ: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggles active/published status of an FAQ in Firestore
  Future<bool> toggleFaqActive(String id, bool currentStatus) async {
    try {
      final newStatus = !currentStatus;
      final success = await _faqService.updateFaqOnline(id, {
        'isActive': newStatus,
      });
      if (success) {
        final idx = _faqs.indexWhere((f) => f.id == id);
        if (idx != -1) {
          _faqs[idx] = _faqs[idx].copyWith(isActive: newStatus);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint("Error toggling FAQ status: $e");
      return false;
    }
  }

  /// Real-time stream of FAQs from Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> getFaqsStream(String category) {
    return _faqService.getFaqsStream(category);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FaqModel {
  final String id;
  final String question;
  final String answer;
  final String category; // Expenses, Security, Budgeting, Goals, Reports, General
  bool isActive;
  final DateTime createdAt;
  final int displayOrder;
  final String? createdBy;

  FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.isActive = true,
    required this.createdAt,
    this.displayOrder = 0,
    this.createdBy = 'admin',
  });

  FaqModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    int? displayOrder,
    String? createdBy,
  }) {
    return FaqModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'displayOrder': displayOrder,
      'createdBy': createdBy ?? 'admin',
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory FaqModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    DateTime parsedDate = DateTime.now();
    final rawDate = map['createdAt'] ?? map['updatedAt'];
    if (rawDate != null) {
      if (rawDate is Timestamp) {
        parsedDate = rawDate.toDate();
      } else {
        parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      }
    }

    return FaqModel(
      id: docId,
      question: (map['question'] ?? '').toString(),
      answer: (map['answer'] ?? '').toString(),
      category: (map['category'] ?? 'General').toString(),
      isActive: map['isActive'] ?? true,
      createdAt: parsedDate,
      displayOrder: (map['displayOrder'] is num) ? (map['displayOrder'] as num).toInt() : 0,
      createdBy: map['createdBy']?.toString() ?? 'admin',
    );
  }
}

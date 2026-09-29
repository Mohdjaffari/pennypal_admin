import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LearningContentModel {
  final String id;
  final String title;
  final String category; // Basics, Budgeting, Saving, Goals, Investing, etc.
  final int durationMinutes;
  final String level; // Beginner, Intermediate, Advanced
  final String description;
  final String content;
  final String imageUrl;
  final DateTime publishedDate;
  bool isFeatured;
  int readCount;
  final String? createdBy;
  final String sourceCollection;

  LearningContentModel({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.level,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.publishedDate,
    this.isFeatured = false,
    this.readCount = 0,
    this.createdBy = 'admin',
    this.sourceCollection = 'learning_content',
  });

  LearningContentModel copyWith({
    String? id,
    String? title,
    String? category,
    int? durationMinutes,
    String? level,
    String? description,
    String? content,
    String? imageUrl,
    DateTime? publishedDate,
    bool? isFeatured,
    int? readCount,
    String? createdBy,
    String? sourceCollection,
  }) {
    return LearningContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      level: level ?? this.level,
      description: description ?? this.description,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedDate: publishedDate ?? this.publishedDate,
      isFeatured: isFeatured ?? this.isFeatured,
      readCount: readCount ?? this.readCount,
      createdBy: createdBy ?? this.createdBy,
      sourceCollection: sourceCollection ?? this.sourceCollection,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'durationMinutes': durationMinutes,
      'level': level,
      'description': description,
      'content': content,
      'imageUrl': imageUrl,
      'publishedDate': publishedDate.toIso8601String(),
      'isFeatured': isFeatured,
      'readCount': readCount,
      'createdBy': createdBy ?? 'admin',
      'createdAt': publishedDate.toIso8601String(),
    };
  }

  factory LearningContentModel.fromMap(
    Map<String, dynamic> map, {
    required String docId,
    String sourceCollection = 'learning_content',
  }) {
    try {
      // 1. Date
      DateTime parsedDate = DateTime.now();
      final rawDate = map['publishedDate'] ??
          map['createdAt'] ??
          map['created_at'] ??
          map['timestamp'] ??
          map['date'] ??
          map['updatedAt'] ??
          map['updated_at'];
      if (rawDate != null) {
        if (rawDate is Timestamp) {
          parsedDate = rawDate.toDate();
        } else if (rawDate is int) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
        } else {
          parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
        }
      }

      // 2. Duration minutes
      int parsedDuration = 5;
      final rawDuration = map['durationMinutes'] ??
          map['duration'] ??
          map['readTime'] ??
          map['read_time'] ??
          map['readingTime'] ??
          map['reading_time'] ??
          map['minutes'] ??
          map['time'];
      if (rawDuration is num) {
        parsedDuration = rawDuration.toInt();
      } else if (rawDuration != null) {
        final sanitized =
            rawDuration.toString().replaceAll(RegExp(r'[^0-9]'), '');
        parsedDuration = int.tryParse(sanitized) ?? 5;
      }
      if (parsedDuration <= 0) parsedDuration = 5;

      // 3. Read count
      int parsedReadCount = 0;
      final rawReads = map['readCount'] ??
          map['read_count'] ??
          map['reads'] ??
          map['views'] ??
          map['viewCount'] ??
          map['view_count'] ??
          map['viewsCount'];
      if (rawReads is num) {
        parsedReadCount = rawReads.toInt();
      } else if (rawReads != null) {
        final sanitized =
            rawReads.toString().replaceAll(RegExp(r'[^0-9]'), '');
        parsedReadCount = int.tryParse(sanitized) ?? 0;
      }

      // 4. Title
      String title = (map['title'] ??
              map['name'] ??
              map['heading'] ??
              map['topic'] ??
              map['title_en'] ??
              map['subject'] ??
              'Financial Guide')
          .toString()
          .trim();
      if (title.isEmpty) title = 'Financial Guide';

      // 5. Category
      String category = (map['category'] ??
              map['categoryName'] ??
              map['category_name'] ??
              map['type'] ??
              map['tag'] ??
              map['topic'] ??
              'Basics')
          .toString()
          .trim();
      if (category.isEmpty) category = 'Basics';

      // 6. Level / Difficulty
      String level = (map['level'] ??
              map['difficulty'] ??
              map['grade'] ??
              'Beginner')
          .toString()
          .trim();
      if (level.isEmpty) level = 'Beginner';

      // 7. Description & Content
      String description = (map['description'] ??
              map['desc'] ??
              map['summary'] ??
              map['subTitle'] ??
              map['subtitle'] ??
              map['shortDescription'] ??
              map['short_description'] ??
              map['excerpt'] ??
              '')
          .toString()
          .trim();

      String content = (map['content'] ??
              map['body'] ??
              map['article'] ??
              map['details'] ??
              map['text'] ??
              map['description'] ??
              '')
          .toString()
          .trim();

      if (content.isEmpty && description.isNotEmpty) {
        content = description;
      } else if (description.isEmpty && content.isNotEmpty) {
        description = content.length > 130
            ? '${content.substring(0, 127)}...'
            : content;
      }

      // 8. Image URL
      String imageUrl = (map['imageUrl'] ??
              map['image'] ??
              map['bannerUrl'] ??
              map['coverImage'] ??
              map['thumbnail'] ??
              map['photoUrl'] ??
              map['banner'] ??
              map['img'] ??
              map['photo'] ??
              map['pic'] ??
              map['url'] ??
              '')
          .toString()
          .trim();

      // 9. Featured
      final isFeatured = map['isFeatured'] == true ||
          map['featured'] == true ||
          map['is_featured'] == true ||
          map['isHighlight'] == true ||
          map['highlight'] == true;

      // 10. Created By
      String createdBy = (map['createdBy'] ??
              map['created_by'] ??
              map['author'] ??
              'admin')
          .toString();

      return LearningContentModel(
        id: docId,
        title: title,
        category: category,
        durationMinutes: parsedDuration,
        level: level,
        description: description,
        content: content,
        imageUrl: imageUrl,
        publishedDate: parsedDate,
        isFeatured: isFeatured,
        readCount: parsedReadCount,
        createdBy: createdBy,
        sourceCollection: sourceCollection,
      );
    } catch (e) {
      debugPrint("LearningContentModel.fromMap fallback for $docId: $e");
      return LearningContentModel(
        id: docId,
        title: (map['title'] ?? map['name'] ?? 'Guide #$docId').toString(),
        category: (map['category'] ?? 'General').toString(),
        durationMinutes: 5,
        level: 'Beginner',
        description: (map['description'] ?? map['content'] ?? '').toString(),
        content: (map['content'] ?? map['description'] ?? '').toString(),
        imageUrl: (map['imageUrl'] ?? map['image'] ?? '').toString(),
        publishedDate: DateTime.now(),
        sourceCollection: sourceCollection,
      );
    }
  }
}

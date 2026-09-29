import 'package:cloud_firestore/cloud_firestore.dart';

class LearningContentModel {
  final String id;
  final String title;
  final String category; // Basics, Budgeting, Saving, Goals, Investing
  final int durationMinutes;
  final String level; // Beginner, Intermediate, Advanced
  final String description;
  final String content;
  final String imageUrl;
  final DateTime publishedDate;
  bool isFeatured;
  int readCount;
  final String? createdBy;

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
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory LearningContentModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    DateTime parsedDate = DateTime.now();
    final rawDate = map['publishedDate'] ??
        map['createdAt'] ??
        map['created_at'] ??
        map['timestamp'] ??
        map['date'];
    if (rawDate != null) {
      if (rawDate is Timestamp) {
        parsedDate = rawDate.toDate();
      } else if (rawDate is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
      } else {
        parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      }
    }

    // Parse duration minutes from int, double, or String (e.g. '5', '5 min')
    int parsedDuration = 5;
    final rawDuration = map['durationMinutes'] ??
        map['duration'] ??
        map['readTime'] ??
        map['read_time'] ??
        map['minutes'];
    if (rawDuration is num) {
      parsedDuration = rawDuration.toInt();
    } else if (rawDuration != null) {
      final sanitized = rawDuration.toString().replaceAll(RegExp(r'[^0-9]'), '');
      parsedDuration = int.tryParse(sanitized) ?? 5;
    }

    // Parse readCount from num or String
    int parsedReadCount = 0;
    final rawReads = map['readCount'] ??
        map['read_count'] ??
        map['reads'] ??
        map['views'] ??
        map['viewCount'];
    if (rawReads is num) {
      parsedReadCount = rawReads.toInt();
    } else if (rawReads != null) {
      final sanitized = rawReads.toString().replaceAll(RegExp(r'[^0-9]'), '');
      parsedReadCount = int.tryParse(sanitized) ?? 0;
    }

    // Resolve title
    final title = (map['title'] ??
            map['name'] ??
            map['heading'] ??
            map['topic'] ??
            'Financial Learning Guide')
        .toString();

    // Resolve category
    final category = (map['category'] ??
            map['categoryName'] ??
            map['type'] ??
            map['tag'] ??
            'Basics')
        .toString();

    // Resolve level
    final level = (map['level'] ??
            map['difficulty'] ??
            map['grade'] ??
            'Beginner')
        .toString();

    // Resolve description
    final description = (map['description'] ??
            map['desc'] ??
            map['summary'] ??
            map['subTitle'] ??
            map['shortDescription'] ??
            '')
        .toString();

    // Resolve content
    final content = (map['content'] ??
            map['body'] ??
            map['article'] ??
            map['details'] ??
            map['description'] ??
            '')
        .toString();

    // Resolve image URL
    final imageUrl = (map['imageUrl'] ??
            map['image'] ??
            map['bannerUrl'] ??
            map['coverImage'] ??
            map['thumbnail'] ??
            map['photoUrl'] ??
            '')
        .toString();

    // Resolve isFeatured
    final isFeatured = map['isFeatured'] == true ||
        map['featured'] == true ||
        map['is_featured'] == true;

    // Resolve createdBy
    final createdBy = (map['createdBy'] ??
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
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userName;
  final String userEmail;
  final int rating; // 1 to 5 stars
  final String feedbackType; // App Experience, Feature Request, Bug Report, General
  final String comments;
  final DateTime submittedAt;
  bool isReviewed;
  final String? userId;

  FeedbackModel({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.feedbackType,
    required this.comments,
    required this.submittedAt,
    this.isReviewed = false,
    this.userId,
  });

  String get userInitials {
    final cleanName = userName.trim();
    if (cleanName.isNotEmpty) {
      final parts = cleanName.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return cleanName[0].toUpperCase();
    }
    final cleanEmail = userEmail.trim();
    if (cleanEmail.isNotEmpty) {
      return cleanEmail[0].toUpperCase();
    }
    return 'U';
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(submittedAt);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo ago';
    return '${(difference.inDays / 365).floor()}y ago';
  }

  FeedbackModel copyWith({
    String? id,
    String? userName,
    String? userEmail,
    int? rating,
    String? feedbackType,
    String? comments,
    DateTime? submittedAt,
    bool? isReviewed,
    String? userId,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      rating: rating ?? this.rating,
      feedbackType: feedbackType ?? this.feedbackType,
      comments: comments ?? this.comments,
      submittedAt: submittedAt ?? this.submittedAt,
      isReviewed: isReviewed ?? this.isReviewed,
      userId: userId ?? this.userId,
    );
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      if (d is Timestamp) return d.toDate();
      if (d.runtimeType.toString().contains('Timestamp')) {
        try {
          return (d as dynamic).toDate();
        } catch (_) {}
      }
      if (d is num) {
        if (d > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(d.toInt());
        } else {
          return DateTime.fromMillisecondsSinceEpoch((d * 1000).toInt());
        }
      }
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    int parseRating(dynamic r) {
      if (r == null) return 5;
      if (r is num) return r.toInt().clamp(1, 5);
      final parsed = int.tryParse(r.toString());
      if (parsed != null) return parsed.clamp(1, 5);
      final doubleParsed = double.tryParse(r.toString());
      if (doubleParsed != null) return doubleParsed.round().clamp(1, 5);
      return 5;
    }

    bool parseReviewed(dynamic rev, dynamic status) {
      if (rev == true) return true;
      if (status != null) {
        final st = status.toString().toLowerCase();
        if (st == 'reviewed' || st == 'resolved' || st == 'read' || st == 'completed') {
          return true;
        }
      }
      return false;
    }

    return FeedbackModel(
      id: docId ?? map['id']?.toString() ?? map['feedbackId']?.toString() ?? '',
      userName: (map['user_name'] ?? map['userName'] ?? map['name'] ?? map['senderName'] ?? map['fullName'] ?? 'PennyPal User').toString(),
      userEmail: (map['user_email'] ?? map['userEmail'] ?? map['email'] ?? map['senderEmail'] ?? '').toString(),
      rating: parseRating(map['rating'] ?? map['stars']),
      feedbackType: (map['category'] ?? map['feedbackType'] ?? map['type'] ?? 'General').toString(),
      comments: (map['feedback_text'] ?? map['feedbackText'] ?? map['comments'] ?? map['comment'] ?? map['message'] ?? map['feedback'] ?? map['review'] ?? '').toString(),
      submittedAt: parseDate(map['created_at'] ?? map['submittedAt'] ?? map['createdAt'] ?? map['timestamp'] ?? map['date']),
      isReviewed: parseReviewed(map['isReviewed'], map['status']),
      userId: (map['user_id'] ?? map['userId'] ?? map['uid'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'feedbackType': feedbackType,
      'comments': comments,
      'submittedAt': submittedAt.toIso8601String(),
      'isReviewed': isReviewed,
      if (userId != null) 'userId': userId,
    };
  }
}

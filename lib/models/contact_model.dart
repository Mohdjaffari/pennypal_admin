import 'package:cloud_firestore/cloud_firestore.dart';

enum ContactStatus { newMsg, inProgress, resolved }

class ContactMessageModel {
  final String id;
  final String senderName;
  final String senderEmail;
  final String phone;
  final String subject;
  final String message;
  final DateTime submittedAt;
  ContactStatus status;
  String? adminReply;
  DateTime? repliedAt;
  final String? userId;

  ContactMessageModel({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.phone,
    required this.subject,
    required this.message,
    required this.submittedAt,
    this.status = ContactStatus.newMsg,
    this.adminReply,
    this.repliedAt,
    this.userId,
  });

  String get senderInitials {
    final cleanName = senderName.trim();
    if (cleanName.isNotEmpty) {
      final parts = cleanName.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return cleanName[0].toUpperCase();
    }
    final cleanEmail = senderEmail.trim();
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

  ContactMessageModel copyWith({
    String? id,
    String? senderName,
    String? senderEmail,
    String? phone,
    String? subject,
    String? message,
    DateTime? submittedAt,
    ContactStatus? status,
    String? adminReply,
    DateTime? repliedAt,
    String? userId,
  }) {
    return ContactMessageModel(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      phone: phone ?? this.phone,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
      userId: userId ?? this.userId,
    );
  }

  factory ContactMessageModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    ContactStatus parseStatus(dynamic s) {
      if (s == null) return ContactStatus.newMsg;
      final str = s.toString().toLowerCase().trim();
      if (str == 'resolved' || str == 'closed' || str == 'completed' || str == 'replied' || str == '2') {
        return ContactStatus.resolved;
      }
      if (str == 'inprogress' || str == 'in_progress' || str == 'in progress' || str == 'processing' || str == '1') {
        return ContactStatus.inProgress;
      }
      if (str == 'pending' || str == 'new' || str == 'newmsg' || str == 'unread' || str == '0') {
        return ContactStatus.newMsg;
      }
      return ContactStatus.newMsg;
    }

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

    return ContactMessageModel(
      id: docId ?? map['id']?.toString() ?? map['messageId']?.toString() ?? '',
      senderName: (map['name'] ?? map['senderName'] ?? map['userName'] ?? map['fullName'] ?? 'Anonymous').toString(),
      senderEmail: (map['email'] ?? map['senderEmail'] ?? map['userEmail'] ?? '').toString(),
      phone: (map['phone'] ?? map['phoneNumber'] ?? map['contact'] ?? map['mobile'] ?? '').toString(),
      subject: (map['category'] ?? map['subject'] ?? map['title'] ?? map['topic'] ?? 'General Inquiry').toString(),
      message: (map['message'] ?? map['msg'] ?? map['body'] ?? map['content'] ?? map['query'] ?? '').toString(),
      submittedAt: parseDate(map['created_at'] ?? map['submittedAt'] ?? map['createdAt'] ?? map['timestamp'] ?? map['date']),
      status: parseStatus(map['status']),
      adminReply: (map['adminReply'] ?? map['reply'])?.toString(),
      repliedAt: (map['repliedAt'] != null || map['respondedAt'] != null)
          ? parseDate(map['repliedAt'] ?? map['respondedAt'])
          : null,
      userId: (map['user_id'] ?? map['userId'] ?? map['uid'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    String statusStr = 'newMsg';
    if (status == ContactStatus.resolved) statusStr = 'resolved';
    if (status == ContactStatus.inProgress) statusStr = 'inProgress';

    return {
      'id': id,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'phone': phone,
      'subject': subject,
      'message': message,
      'submittedAt': submittedAt.toIso8601String(),
      'status': statusStr,
      'adminReply': adminReply,
      'repliedAt': repliedAt?.toIso8601String(),
      if (userId != null) 'userId': userId,
    };
  }
}

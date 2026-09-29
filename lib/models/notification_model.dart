import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum NotificationType {
  userRegistered,
  contactMessage,
  feedbackReceived,
  learningPublished,
  broadcastAnnouncement,
  systemAlert,
}

enum NotificationTarget {
  admin,
  users,
  all,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationTarget target;
  final DateTime createdAt;
  bool isRead;
  final String? referenceId;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.target = NotificationTarget.all,
    required this.createdAt,
    this.isRead = false,
    this.referenceId,
    this.metadata,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }

  IconData get icon {
    switch (type) {
      case NotificationType.userRegistered:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.contactMessage:
        return Icons.mail_outline_rounded;
      case NotificationType.feedbackReceived:
        return Icons.star_rate_rounded;
      case NotificationType.learningPublished:
        return Icons.school_rounded;
      case NotificationType.broadcastAnnouncement:
        return Icons.campaign_rounded;
      case NotificationType.systemAlert:
        return Icons.shield_outlined;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.userRegistered:
        return AppColors.primary;
      case NotificationType.contactMessage:
        return AppColors.accentPink;
      case NotificationType.feedbackReceived:
        return const Color(0xFFF59E0B); // Amber
      case NotificationType.learningPublished:
        return AppColors.purple;
      case NotificationType.broadcastAnnouncement:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.systemAlert:
        return const Color(0xFF64748B); // Slate
    }
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.userRegistered:
        return 'New User Registration';
      case NotificationType.contactMessage:
        return 'Customer Support Inquiry';
      case NotificationType.feedbackReceived:
        return 'User App Review';
      case NotificationType.learningPublished:
        return 'Academy Content Published';
      case NotificationType.broadcastAnnouncement:
        return 'User Broadcast Notice';
      case NotificationType.systemAlert:
        return 'Platform Security Alert';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationTarget? target,
    DateTime? createdAt,
    bool? isRead,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      target: target ?? this.target,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
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

    NotificationType parseType(dynamic t) {
      final s = (t ?? '').toString().toLowerCase();
      if (s.contains('user') || s.contains('register') || s.contains('account')) {
        return NotificationType.userRegistered;
      }
      if (s.contains('contact') || s.contains('inquiry') || s.contains('message') || s.contains('support')) {
        return NotificationType.contactMessage;
      }
      if (s.contains('feedback') || s.contains('review') || s.contains('rating')) {
        return NotificationType.feedbackReceived;
      }
      if (s.contains('learning') || s.contains('article') || s.contains('academy')) {
        return NotificationType.learningPublished;
      }
      if (s.contains('broadcast') || s.contains('announcement') || s.contains('notice')) {
        return NotificationType.broadcastAnnouncement;
      }
      return NotificationType.systemAlert;
    }

    NotificationTarget parseTarget(dynamic tg) {
      final s = (tg ?? '').toString().toLowerCase();
      if (s == 'admin') return NotificationTarget.admin;
      if (s == 'users' || s == 'user') return NotificationTarget.users;
      return NotificationTarget.all;
    }

    return NotificationModel(
      id: docId ?? map['id'] ?? '',
      title: (map['title'] ?? 'Notification').toString(),
      message: (map['message'] ?? map['body'] ?? '').toString(),
      type: parseType(map['type']),
      target: parseTarget(map['target']),
      createdAt: parseDate(map['createdAt'] ?? map['timestamp'] ?? map['date']),
      isRead: map['isRead'] == true || map['read'] == true,
      referenceId: map['referenceId']?.toString(),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    String typeStr = 'systemAlert';
    switch (type) {
      case NotificationType.userRegistered:
        typeStr = 'user_registered';
        break;
      case NotificationType.contactMessage:
        typeStr = 'contact_message';
        break;
      case NotificationType.feedbackReceived:
        typeStr = 'feedback_received';
        break;
      case NotificationType.learningPublished:
        typeStr = 'learning_published';
        break;
      case NotificationType.broadcastAnnouncement:
        typeStr = 'broadcast_announcement';
        break;
      case NotificationType.systemAlert:
        typeStr = 'system_alert';
        break;
    }

    String targetStr = 'all';
    switch (target) {
      case NotificationTarget.admin:
        targetStr = 'admin';
        break;
      case NotificationTarget.users:
        targetStr = 'users';
        break;
      case NotificationTarget.all:
        targetStr = 'all';
        break;
    }

    return {
      'id': id,
      'title': title,
      'message': message,
      'type': typeStr,
      'target': targetStr,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (referenceId != null) 'referenceId': referenceId,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

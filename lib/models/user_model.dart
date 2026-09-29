class UserModel {
  final String id;
  String get uid => id;

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final emailTrimmed = email.trim();
    if (emailTrimmed.isNotEmpty) return emailTrimmed.split('@').first;
    return 'User';
  }

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.substring(0, 1).toUpperCase();
    }
    final emailTrimmed = email.trim();
    if (emailTrimmed.isNotEmpty) {
      return emailTrimmed.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  final String name;
  final String email;
  final String phone;
  final String role;
  bool isBlocked;
  final String avatarUrl;
  final DateTime joinedDate;
  final double totalBalance;
  final double totalExpenses;
  final double savings;
  final int totalTransactions;

  UserModel({
    String? id,
    String? uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'user',
    this.isBlocked = false,
    this.avatarUrl = '',
    DateTime? joinedDate,
    this.totalBalance = 0.0,
    this.totalExpenses = 0.0,
    this.savings = 0.0,
    this.totalTransactions = 0,
  })  : id = id ?? uid ?? '',
        joinedDate = joinedDate ?? DateTime.now();

  UserModel copyWith({
    String? id,
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isBlocked,
    String? avatarUrl,
    DateTime? joinedDate,
    double? totalBalance,
    double? totalExpenses,
    double? savings,
    int? totalTransactions,
  }) {
    return UserModel(
      id: id ?? uid ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isBlocked: isBlocked ?? this.isBlocked,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      totalBalance: totalBalance ?? this.totalBalance,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      savings: savings ?? this.savings,
      totalTransactions: totalTransactions ?? this.totalTransactions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isBlocked': isBlocked,
      'avatarUrl': avatarUrl,
      'createdAt': joinedDate.toIso8601String(),
      'totalBalance': totalBalance,
      'totalExpenses': totalExpenses,
      'savings': savings,
      'totalTransactions': totalTransactions,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final effectiveId = docId ?? map['uid'] ?? map['id'] ?? '';
    DateTime joined = DateTime.now();
    final rawDate = map['createdAt'] ?? map['joinedDate'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        joined = rawDate;
      } else if (rawDate.runtimeType.toString().contains('Timestamp')) {
        joined = (rawDate as dynamic).toDate();
      } else {
        joined = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      }
    }

    return UserModel(
      id: effectiveId.toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: (map['role'] ?? 'Standard User').toString(),
      isBlocked: map['isBlocked'] == true,
      avatarUrl: (map['avatarUrl'] ?? '').toString(),
      joinedDate: joined,
      totalBalance: (map['totalBalance'] is num)
          ? (map['totalBalance'] as num).toDouble()
          : 0.0,
      totalExpenses: (map['totalExpenses'] is num)
          ? (map['totalExpenses'] as num).toDouble()
          : 0.0,
      savings: (map['savings'] is num)
          ? (map['savings'] as num).toDouble()
          : 0.0,
      totalTransactions: (map['totalTransactions'] is num)
          ? (map['totalTransactions'] as num).toInt()
          : 0,
    );
  }
}

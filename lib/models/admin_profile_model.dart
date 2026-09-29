class AdminProfileModel {
  String id;
  String name;
  String email;
  String phone;
  String role;
  String department;
  String avatarUrl;
  final DateTime joinedDate;
  DateTime lastLogin;
  bool is2faEnabled;
  String bio;

  AdminProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.avatarUrl,
    required this.joinedDate,
    required this.lastLogin,
    this.is2faEnabled = true,
    this.bio = 'PennyPal Core Systems Administrator overseeing security, content, user moderation, and financial compliance.',
  });

  AdminProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? department,
    String? avatarUrl,
    DateTime? joinedDate,
    DateTime? lastLogin,
    bool? is2faEnabled,
    String? bio,
  }) {
    return AdminProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      lastLogin: lastLogin ?? this.lastLogin,
      is2faEnabled: is2faEnabled ?? this.is2faEnabled,
      bio: bio ?? this.bio,
    );
  }

  factory AdminProfileModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return AdminProfileModel(
      id: docId ?? map['id'] ?? map['uid'] ?? 'admin',
      name: map['name'] ?? map['displayName'] ?? 'Administrator',
      email: map['email'] ?? 'admin@pennypal.app',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'Super Administrator',
      department: map['department'] ?? 'Finance & Systems Ops',
      avatarUrl: map['avatarUrl'] ?? map['photoUrl'] ?? '',
      joinedDate: parseDate(map['joinedDate'] ?? map['createdAt']),
      lastLogin: parseDate(map['lastLogin']),
      is2faEnabled: map['is2faEnabled'] ?? true,
      bio: map['bio'] ?? 'PennyPal Core Systems Administrator.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department,
      'avatarUrl': avatarUrl,
      'joinedDate': joinedDate.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'is2faEnabled': is2faEnabled,
      'bio': bio,
    };
  }
}

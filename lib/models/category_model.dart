import 'dart:ui';

class CategoryModel {
  final String? id;
  final String name;
  final String type; // 'expense', 'income', or 'learning'
  final String? icon; // Cloudinary URL or asset path
  final bool isDefault; // true for admin categories
  final bool isSystemDefault; // alias for admin compatibility
  final String? createdBy; // 'admin' or userId
  final int isSynced; // 0 = local/offline, 1 = synced to Firestore

  // UI & compatibility helper fields
  final String iconName;
  final int colorValue;
  final int usageCount;
  bool isVisibleToUser;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.isDefault = false,
    bool? isSystemDefault,
    this.createdBy,
    this.isSynced = 0,
    this.iconName = 'category',
    this.colorValue = 0xFF2563EB,
    this.usageCount = 0,
    this.isVisibleToUser = true,
  }) : isSystemDefault = isSystemDefault ?? isDefault;

  CategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    bool? isDefault,
    bool? isSystemDefault,
    String? createdBy,
    int? isSynced,
    String? iconName,
    int? colorValue,
    int? usageCount,
    bool? isVisibleToUser,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
      createdBy: createdBy ?? this.createdBy,
      isSynced: isSynced ?? this.isSynced,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      usageCount: usageCount ?? this.usageCount,
      isVisibleToUser: isVisibleToUser ?? this.isVisibleToUser,
    );
  }

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'categoryName': name,
      'categoryType': type.toLowerCase(),
      'icon': icon ?? '',
      'iconName': iconName,
      'colorValue': colorValue,
      'isDefault': isDefault,
      'createdBy': createdBy ?? 'admin',
      'isSynced': 1,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    final catType = (map['categoryType'] ?? map['type'] ?? 'expense').toString().toLowerCase();
    final catName = (map['categoryName'] ?? map['name'] ?? '').toString();
    final catIcon = map['icon']?.toString();

    int color = 0xFF2563EB;
    String fallbackIconName = 'category';
    if (catType == 'expense') {
      color = 0xFFFF3366;
      fallbackIconName = 'shopping_bag_rounded';
    } else if (catType == 'income') {
      color = 0xFF10B981;
      fallbackIconName = 'payments_rounded';
    } else if (catType == 'learning') {
      color = 0xFF8B5CF6;
      fallbackIconName = 'school_rounded';
    }

    final isDef = map['isDefault'] ?? false;
    final resolvedIconName = (map['iconName'] != null && map['iconName'].toString().isNotEmpty)
        ? map['iconName'].toString()
        : (catIcon != null && !catIcon.startsWith('http') && catIcon.isNotEmpty
            ? catIcon
            : fallbackIconName);

    return CategoryModel(
      id: docId,
      name: catName,
      type: catType,
      icon: catIcon,
      isDefault: isDef,
      isSystemDefault: isDef,
      createdBy: map['createdBy'] ?? 'admin',
      isSynced: 1,
      iconName: resolvedIconName,
      colorValue: map['colorValue'] ?? color,
      usageCount: (map['usageCount'] is num) ? (map['usageCount'] as num).toInt() : 0,
      isVisibleToUser: map['isVisibleToUser'] ?? true,
    );
  }

  Map<String, dynamic> toSqfliteMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toLowerCase(),
      'icon': icon ?? '',
      'is_default': isDefault ? 1 : 0,
      'created_by': createdBy ?? 'admin',
      'is_synced': isSynced,
    };
  }

  factory CategoryModel.fromSqfliteMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'] ?? '',
      type: (map['type'] ?? 'expense').toString().toLowerCase(),
      icon: map['icon'],
      isDefault: (map['is_default'] ?? 0) == 1,
      isSystemDefault: (map['is_default'] ?? 0) == 1,
      createdBy: map['created_by'],
      isSynced: map['is_synced'] ?? 0,
    );
  }
}

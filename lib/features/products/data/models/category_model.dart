// lib/features/products/data/models/category_model.dart

class CategoryModel {
  final String id;
  final String name;
  final String? parentId;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  final List<CategoryModel> children;
  final CategoryModel? parent;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.children = const [],
    this.parent,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      children: _parseChildren(json['children']),
      parent: json['parent'] != null
          ? CategoryModel.fromJson(json['parent'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parent_id': parentId,
      'description': description,
      'is_active': isActive,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? parentId,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    List<CategoryModel>? children,
    CategoryModel? parent,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
      parent: parent ?? this.parent,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static List<CategoryModel> _parseChildren(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  bool get isMain => parentId == null;
  bool get isSub => parentId != null;
  bool get hasChildren => children.isNotEmpty;
  int get childrenCount => children.length;
}

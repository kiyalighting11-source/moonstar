// lib/features/employees/data/models/department_model.dart

class DepartmentModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  DepartmentModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}

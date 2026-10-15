// lib/features/employees/data/models/job_title_model.dart

class JobTitleModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  JobTitleModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory JobTitleModel.fromJson(Map<String, dynamic> json) {
    return JobTitleModel(
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

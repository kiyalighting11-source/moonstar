// lib/features/employees/data/models/employee_model.dart

class EmployeeModel {
  final String id;
  final String? profileId;
  final String employeeCode;
  final String fullName;
  final String? nationalId;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime? birthDate;
  final String? gender; // male / female
  final String? jobTitle;
  final String? department;
  final double basicSalary;
  final DateTime? hireDate;
  final DateTime? terminationDate;
  final bool isActive;
  final String? notes;

  // ⭐ Device Registration
  final String? deviceId;
  final DateTime? deviceRegisteredAt;
  final String? deviceRegisteredBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmployeeModel({
    required this.id,
    this.profileId,
    required this.employeeCode,
    required this.fullName,
    this.nationalId,
    this.phone,
    this.email,
    this.address,
    this.birthDate,
    this.gender,
    this.jobTitle,
    this.department,
    this.basicSalary = 0,
    this.hireDate,
    this.terminationDate,
    this.isActive = true,
    this.notes,
    this.deviceId,
    this.deviceRegisteredAt,
    this.deviceRegisteredBy,
    this.createdAt,
    this.updatedAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String?,
      employeeCode: json['employee_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      nationalId: json['national_id'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      birthDate: _parseDate(json['birth_date']),
      gender: json['gender'] as String?,
      jobTitle: json['job_title'] as String?,
      department: json['department'] as String?,
      basicSalary: _parseDouble(json['basic_salary']),
      hireDate: _parseDate(json['hire_date']),
      terminationDate: _parseDate(json['termination_date']),
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      deviceId: json['device_id'] as String?,
      deviceRegisteredAt: _parseDateTime(json['device_registered_at']),
      deviceRegisteredBy: json['device_registered_by'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (employeeCode.isNotEmpty) 'employee_code': employeeCode,
      'full_name': fullName,
      'national_id': nationalId,
      'phone': phone,
      'email': email,
      'address': address,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'gender': gender,
      'job_title': jobTitle,
      'department': department,
      'basic_salary': basicSalary,
      'hire_date': hireDate?.toIso8601String().split('T').first,
      'termination_date': terminationDate?.toIso8601String().split('T').first,
      'is_active': isActive,
      'notes': notes,
      'profile_id': profileId,
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? profileId,
    String? employeeCode,
    String? fullName,
    String? nationalId,
    String? phone,
    String? email,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? jobTitle,
    String? department,
    double? basicSalary,
    DateTime? hireDate,
    DateTime? terminationDate,
    bool? isActive,
    String? notes,
    String? deviceId,
    DateTime? deviceRegisteredAt,
    String? deviceRegisteredBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDevice = false,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      basicSalary: basicSalary ?? this.basicSalary,
      hireDate: hireDate ?? this.hireDate,
      terminationDate: terminationDate ?? this.terminationDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      deviceId: clearDevice ? null : (deviceId ?? this.deviceId),
      deviceRegisteredAt:
          clearDevice ? null : (deviceRegisteredAt ?? this.deviceRegisteredAt),
      deviceRegisteredBy:
          clearDevice ? null : (deviceRegisteredBy ?? this.deviceRegisteredBy),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============ Getters ============
  bool get isMale => gender == 'male';

  /// هل الموظف عنده جهاز مسجل؟
  bool get hasRegisteredDevice => deviceId != null && deviceId!.isNotEmpty;

  // ============ Parsers ============
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}

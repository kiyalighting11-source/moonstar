// lib/features/attendance/data/models/attendance_model.dart

class AttendanceModel {
  final String id;
  final String employeeId;
  final DateTime date;

  // أوقات
  final DateTime? checkIn;
  final DateTime? checkOut;

  // معلومات الجهاز والموقع
  final String? deviceIdUsed;
  final double? locationLat;
  final double? locationLng;
  final double? distanceFromCompany;

  // أجهزة الـ checkin/checkout (من الداتابيز القديمة)
  final String? checkInDevice;
  final String? checkOutDevice;
  final String? checkInIp;
  final String? checkOutIp;

  // دقايق
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final int workedMinutes;

  // الحالة
  final String status; // present, late, very_late, absent, weekend
  final bool isVeryLate;
  final String? note;

  // من سجّل
  final String? registeredBy;

  // علاقات
  final String? employeeName;
  final String? employeeCode;
  final String? employeeJobTitle;
  final String? employeeImageUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.deviceIdUsed,
    this.locationLat,
    this.locationLng,
    this.distanceFromCompany,
    this.checkInDevice,
    this.checkOutDevice,
    this.checkInIp,
    this.checkOutIp,
    this.lateMinutes = 0,
    this.earlyLeaveMinutes = 0,
    this.workedMinutes = 0,
    this.status = 'absent',
    this.isVeryLate = false,
    this.note,
    this.registeredBy,
    this.employeeName,
    this.employeeCode,
    this.employeeJobTitle,
    this.employeeImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final emp = json['employees'];
    return AttendanceModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      date: _parseDate(json['date']) ?? DateTime.now(),
      checkIn: _parseDateTime(json['check_in']),
      checkOut: _parseDateTime(json['check_out']),
      deviceIdUsed: json['device_id_used'] as String?,
      locationLat: _parseDouble(json['location_lat']),
      locationLng: _parseDouble(json['location_lng']),
      distanceFromCompany: _parseDouble(json['distance_from_company']),
      checkInDevice: json['check_in_device'] as String?,
      checkOutDevice: json['check_out_device'] as String?,
      checkInIp: json['check_in_ip'] as String?,
      checkOutIp: json['check_out_ip'] as String?,
      lateMinutes: _parseInt(json['late_minutes']),
      earlyLeaveMinutes: _parseInt(json['early_leave_minutes']),
      workedMinutes: _parseInt(json['worked_minutes']),
      status: json['status'] as String? ?? 'absent',
      isVeryLate: json['is_very_late'] as bool? ?? false,
      note: json['note'] as String?,
      registeredBy: json['registered_by'] as String?,
      employeeName: emp is Map ? emp['full_name'] as String? : null,
      employeeCode: emp is Map ? emp['employee_code'] as String? : null,
      employeeJobTitle: emp is Map ? emp['job_title'] as String? : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'date': date.toIso8601String().split('T').first,
      if (checkIn != null) 'check_in': checkIn!.toIso8601String(),
      if (checkOut != null) 'check_out': checkOut!.toIso8601String(),
      'device_id_used': deviceIdUsed,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'distance_from_company': distanceFromCompany,
      'late_minutes': lateMinutes,
      'early_leave_minutes': earlyLeaveMinutes,
      'worked_minutes': workedMinutes,
      'status': status,
      'is_very_late': isVeryLate,
      'note': note,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    String? deviceIdUsed,
    double? locationLat,
    double? locationLng,
    double? distanceFromCompany,
    int? lateMinutes,
    int? earlyLeaveMinutes,
    int? workedMinutes,
    String? status,
    bool? isVeryLate,
    String? note,
    String? registeredBy,
    String? employeeName,
    String? employeeCode,
    String? employeeJobTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      deviceIdUsed: deviceIdUsed ?? this.deviceIdUsed,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      distanceFromCompany: distanceFromCompany ?? this.distanceFromCompany,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      earlyLeaveMinutes: earlyLeaveMinutes ?? this.earlyLeaveMinutes,
      workedMinutes: workedMinutes ?? this.workedMinutes,
      status: status ?? this.status,
      isVeryLate: isVeryLate ?? this.isVeryLate,
      note: note ?? this.note,
      registeredBy: registeredBy ?? this.registeredBy,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeJobTitle: employeeJobTitle ?? this.employeeJobTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============ Getters مساعدة ============
  bool get hasCheckedIn => checkIn != null;
  bool get hasCheckedOut => checkOut != null;
  bool get isPresent => status == 'present';
  bool get isLate => status == 'late';
  bool get isVeryLateStatus => status == 'very_late' || isVeryLate;
  bool get isAbsent => status == 'absent';
  bool get isWeekend => status == 'weekend';
  bool get isComplete => hasCheckedIn && hasCheckedOut;

  /// اسم الحالة بالعربي
  String get statusLabelAr {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'late':
        return 'متأخر';
      case 'very_late':
        return 'حضر متأخراً جداً';
      case 'absent':
        return 'غايب';
      case 'weekend':
        return 'إجازة أسبوعية';
      default:
        return status;
    }
  }

  /// نص التأخير
  String get lateLabel {
    if (lateMinutes <= 0) return '';
    if (lateMinutes < 60) return 'تأخير $lateMinutes دقيقة';
    final h = lateMinutes ~/ 60;
    final m = lateMinutes % 60;
    if (m == 0) return 'تأخير $h ساعة';
    return 'تأخير $h س و $m د';
  }

  /// نص الخروج المبكر
  String get earlyLeaveLabel {
    if (earlyLeaveMinutes <= 0) return '';
    if (earlyLeaveMinutes < 60) return 'خروج مبكر $earlyLeaveMinutes دقيقة';
    final h = earlyLeaveMinutes ~/ 60;
    final m = earlyLeaveMinutes % 60;
    if (m == 0) return 'خروج مبكر $h ساعة';
    return 'خروج مبكر $h س و $m د';
  }

  // ============ Parsers ============
  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}

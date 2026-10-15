// lib/core/models/settings_model.dart

class SettingsModel {
  final String id;
  final String companyName;
  final String? companyLogoUrl;
  final String? companyPhone;
  final String? companyAddress;
  final String? companyEmail;

  // العملة
  final String currencyCode;
  final String currencySymbol;

  // الشيفت
  final String shiftStartTime; // "13:30"
  final String shiftEndTime; // "22:30"
  final int graceMinutes;
  final String absenceMarkTime; // "14:30"
  final int weekendDay; // 0 = Sunday

  // الموقع
  final double? companyLat;
  final double? companyLng;
  final int attendanceRadiusMeters;

  // مالية
  final int payrollCycleStartDay;
  final String invoicePrefix;
  final double taxRate;
  final int lowStockThreshold;

  final bool isActive;
  final DateTime? updatedAt;
  final String? updatedBy;

  SettingsModel({
    required this.id,
    this.companyName = 'Moonstar',
    this.companyLogoUrl,
    this.companyPhone,
    this.companyAddress,
    this.companyEmail,
    this.currencyCode = 'EGP',
    this.currencySymbol = 'ج.م',
    this.shiftStartTime = '13:30',
    this.shiftEndTime = '22:30',
    this.graceMinutes = 15,
    this.absenceMarkTime = '14:30',
    this.weekendDay = 0,
    this.companyLat,
    this.companyLng,
    this.attendanceRadiusMeters = 50,
    this.payrollCycleStartDay = 5,
    this.invoicePrefix = 'INV',
    this.taxRate = 0,
    this.lowStockThreshold = 10,
    this.isActive = true,
    this.updatedAt,
    this.updatedBy,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] as String,
      companyName: json['company_name'] as String? ?? 'Moonstar',
      companyLogoUrl: json['company_logo_url'] as String?,
      companyPhone: json['company_phone'] as String?,
      companyAddress: json['company_address'] as String?,
      companyEmail: json['company_email'] as String?,
      currencyCode: json['currency_code'] as String? ?? 'EGP',
      currencySymbol: json['currency_symbol'] as String? ?? 'ج.م',
      shiftStartTime: _parseTime(json['shift_start_time'], '13:30'),
      shiftEndTime: _parseTime(json['shift_end_time'], '22:30'),
      graceMinutes: _parseInt(json['grace_minutes'], fallback: 15),
      absenceMarkTime: _parseTime(json['absence_mark_time'], '14:30'),
      weekendDay: _parseInt(json['weekend_day']),
      companyLat: _parseDoubleOrNull(json['company_lat']),
      companyLng: _parseDoubleOrNull(json['company_lng']),
      attendanceRadiusMeters:
          _parseInt(json['attendance_radius_meters'], fallback: 50),
      payrollCycleStartDay:
          _parseInt(json['payroll_cycle_start_day'], fallback: 5),
      invoicePrefix: json['invoice_prefix'] as String? ?? 'INV',
      taxRate: _parseDouble(json['tax_rate']),
      lowStockThreshold: _parseInt(json['low_stock_threshold'], fallback: 10),
      isActive: json['is_active'] as bool? ?? true,
      updatedAt: _parseDateTime(json['updated_at']),
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'company_logo_url': companyLogoUrl,
      'company_phone': companyPhone,
      'company_address': companyAddress,
      'company_email': companyEmail,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'shift_start_time': shiftStartTime,
      'shift_end_time': shiftEndTime,
      'grace_minutes': graceMinutes,
      'absence_mark_time': absenceMarkTime,
      'weekend_day': weekendDay,
      'company_lat': companyLat,
      'company_lng': companyLng,
      'attendance_radius_meters': attendanceRadiusMeters,
      'payroll_cycle_start_day': payrollCycleStartDay,
      'invoice_prefix': invoicePrefix,
      'tax_rate': taxRate,
      'low_stock_threshold': lowStockThreshold,
      'is_active': isActive,
    };
  }

  SettingsModel copyWith({
    String? id,
    String? companyName,
    String? companyLogoUrl,
    String? companyPhone,
    String? companyAddress,
    String? companyEmail,
    String? currencyCode,
    String? currencySymbol,
    String? shiftStartTime,
    String? shiftEndTime,
    int? graceMinutes,
    String? absenceMarkTime,
    int? weekendDay,
    double? companyLat,
    double? companyLng,
    int? attendanceRadiusMeters,
    int? payrollCycleStartDay,
    String? invoicePrefix,
    double? taxRate,
    int? lowStockThreshold,
    bool? isActive,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      companyPhone: companyPhone ?? this.companyPhone,
      companyAddress: companyAddress ?? this.companyAddress,
      companyEmail: companyEmail ?? this.companyEmail,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      absenceMarkTime: absenceMarkTime ?? this.absenceMarkTime,
      weekendDay: weekendDay ?? this.weekendDay,
      companyLat: companyLat ?? this.companyLat,
      companyLng: companyLng ?? this.companyLng,
      attendanceRadiusMeters:
          attendanceRadiusMeters ?? this.attendanceRadiusMeters,
      payrollCycleStartDay: payrollCycleStartDay ?? this.payrollCycleStartDay,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      taxRate: taxRate ?? this.taxRate,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // ============ Helpers ============
  /// هل اليوم الحالي إجازة أسبوعية؟
  bool get isTodayWeekend => DateTime.now().weekday % 7 == weekendDay;

  /// اسم يوم الإجازة بالعربي
  String get weekendDayNameAr {
    const days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    if (weekendDay < 0 || weekendDay > 6) return '';
    return days[weekendDay];
  }

  // ============ Parsers ============
  static String _parseTime(dynamic v, String fallback) {
    if (v == null) return fallback;
    final s = v.toString();
    if (s.length >= 5) return s.substring(0, 5);
    return fallback;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _parseDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _parseInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
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

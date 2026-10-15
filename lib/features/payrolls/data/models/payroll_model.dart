// lib/features/payrolls/data/models/payroll_model.dart

class PayrollModel {
  final String id;
  final String payrollNumber;
  final String employeeId;

  // فترة القبض
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodLabel;

  // الراتب
  final double basicSalary;
  final double dailyRate;
  final double grossSalary;

  // الحضور
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final int totalLateMinutes;

  // الخصومات
  final double advancesDeduction;
  final double lateDeduction;
  final double absenceDeduction;
  final double otherDeductions;

  // الإضافات
  final double bonus;

  // الصافي
  final double netSalary;

  // تفاصيل السلف (JSON)
  final List<Map<String, dynamic>> advancesDetails;

  // الدفع
  final bool isPaid;
  final DateTime? paidAt;
  final String? paidBy;

  final String? notes;
  final DateTime? createdAt;
  final String? createdBy;

  // علاقات
  final String? employeeName;
  final String? employeeCode;
  final String? employeeJobTitle;
  final String? paidByName;

  PayrollModel({
    required this.id,
    required this.payrollNumber,
    required this.employeeId,
    required this.periodStart,
    required this.periodEnd,
    required this.periodLabel,
    this.basicSalary = 0,
    this.dailyRate = 0,
    this.grossSalary = 0,
    this.workingDays = 0,
    this.presentDays = 0,
    this.absentDays = 0,
    this.totalLateMinutes = 0,
    this.advancesDeduction = 0,
    this.lateDeduction = 0,
    this.absenceDeduction = 0,
    this.otherDeductions = 0,
    this.bonus = 0,
    this.netSalary = 0,
    this.advancesDetails = const [],
    this.isPaid = false,
    this.paidAt,
    this.paidBy,
    this.notes,
    this.createdAt,
    this.createdBy,
    this.employeeName,
    this.employeeCode,
    this.employeeJobTitle,
    this.paidByName,
  });

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    final emp = json['employees'];
    final paidByProfile = json['paid_by_profile'];
    return PayrollModel(
      id: json['id'] as String,
      payrollNumber: json['payroll_number'] as String? ?? '',
      employeeId: json['employee_id'] as String,
      periodStart: _parseDate(json['period_start']) ?? DateTime.now(),
      periodEnd: _parseDate(json['period_end']) ?? DateTime.now(),
      periodLabel: json['period_label'] as String? ?? '',
      basicSalary: _parseDouble(json['basic_salary']),
      dailyRate: _parseDouble(json['daily_rate']),
      grossSalary: _parseDouble(json['gross_salary']),
      workingDays: _parseInt(json['working_days']),
      presentDays: _parseInt(json['present_days']),
      absentDays: _parseInt(json['absent_days']),
      totalLateMinutes: _parseInt(json['total_late_minutes']),
      advancesDeduction: _parseDouble(json['advances_deduction']),
      lateDeduction: _parseDouble(json['late_deduction']),
      absenceDeduction: _parseDouble(json['absence_deduction']),
      otherDeductions: _parseDouble(json['other_deductions']),
      bonus: _parseDouble(json['bonus']),
      netSalary: _parseDouble(json['net_salary']),
      advancesDetails: _parseJsonList(json['advances_details']),
      isPaid: json['is_paid'] as bool? ?? false,
      paidAt: _parseDateTime(json['paid_at']),
      paidBy: json['paid_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      createdBy: json['created_by'] as String?,
      employeeName: emp is Map ? emp['full_name'] as String? : null,
      employeeCode: emp is Map ? emp['employee_code'] as String? : null,
      employeeJobTitle: emp is Map ? emp['job_title'] as String? : null,
      paidByName:
          paidByProfile is Map ? paidByProfile['full_name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'period_start': periodStart.toIso8601String().split('T').first,
      'period_end': periodEnd.toIso8601String().split('T').first,
      'period_label': periodLabel,
      'basic_salary': basicSalary,
      'daily_rate': dailyRate,
      'gross_salary': grossSalary,
      'working_days': workingDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'total_late_minutes': totalLateMinutes,
      'advances_deduction': advancesDeduction,
      'late_deduction': lateDeduction,
      'absence_deduction': absenceDeduction,
      'other_deductions': otherDeductions,
      'bonus': bonus,
      'net_salary': netSalary,
      'advances_details': advancesDetails,
      'notes': notes,
    };
  }

  PayrollModel copyWith({
    String? id,
    String? payrollNumber,
    String? employeeId,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? periodLabel,
    double? basicSalary,
    double? dailyRate,
    double? grossSalary,
    int? workingDays,
    int? presentDays,
    int? absentDays,
    int? totalLateMinutes,
    double? advancesDeduction,
    double? lateDeduction,
    double? absenceDeduction,
    double? otherDeductions,
    double? bonus,
    double? netSalary,
    List<Map<String, dynamic>>? advancesDetails,
    bool? isPaid,
    DateTime? paidAt,
    String? paidBy,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    String? employeeName,
    String? employeeCode,
    String? employeeJobTitle,
    String? paidByName,
  }) {
    return PayrollModel(
      id: id ?? this.id,
      payrollNumber: payrollNumber ?? this.payrollNumber,
      employeeId: employeeId ?? this.employeeId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      periodLabel: periodLabel ?? this.periodLabel,
      basicSalary: basicSalary ?? this.basicSalary,
      dailyRate: dailyRate ?? this.dailyRate,
      grossSalary: grossSalary ?? this.grossSalary,
      workingDays: workingDays ?? this.workingDays,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      totalLateMinutes: totalLateMinutes ?? this.totalLateMinutes,
      advancesDeduction: advancesDeduction ?? this.advancesDeduction,
      lateDeduction: lateDeduction ?? this.lateDeduction,
      absenceDeduction: absenceDeduction ?? this.absenceDeduction,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      bonus: bonus ?? this.bonus,
      netSalary: netSalary ?? this.netSalary,
      advancesDetails: advancesDetails ?? this.advancesDetails,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      paidBy: paidBy ?? this.paidBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeJobTitle: employeeJobTitle ?? this.employeeJobTitle,
      paidByName: paidByName ?? this.paidByName,
    );
  }

  // ============ Getters ============
  double get totalDeductions =>
      advancesDeduction + lateDeduction + absenceDeduction + otherDeductions;

  String get statusLabelAr {
    if (isPaid) return 'تم القبض';
    return 'مستحق';
  }

  // ============ Parsers ============
  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
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

  static List<Map<String, dynamic>> _parseJsonList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }
}

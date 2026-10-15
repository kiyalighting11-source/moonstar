// lib/features/advances/data/models/advance_model.dart

class AdvanceModel {
  final String id;
  final String employeeId;
  final double amount;
  final DateTime advanceDate;
  final String? reason;

  // التقسيط
  final int installmentMonths;
  final double installmentAmount;
  final double remainingAmount;
  final int paidMonths;
  final bool isFullyDeducted;

  // الخصم
  final bool isDeducted;
  final DateTime? deductedAt;
  final String? deductedBy;

  final String? notes;

  // علاقات
  final String? employeeName;
  final String? employeeCode;
  final String? employeeImageUrl;
  final String? createdByName;

  final DateTime? createdAt;
  final String? createdBy;

  AdvanceModel({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.advanceDate,
    this.reason,
    this.installmentMonths = 1,
    this.installmentAmount = 0,
    this.remainingAmount = 0,
    this.paidMonths = 0,
    this.isFullyDeducted = false,
    this.isDeducted = false,
    this.deductedAt,
    this.deductedBy,
    this.notes,
    this.employeeName,
    this.employeeCode,
    this.employeeImageUrl,
    this.createdByName,
    this.createdAt,
    this.createdBy,
  });

  factory AdvanceModel.fromJson(Map<String, dynamic> json) {
    final emp = json['employees'];
    final profile = json['creator'];
    return AdvanceModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      amount: _parseDouble(json['amount']),
      advanceDate: _parseDate(json['advance_date']) ?? DateTime.now(),
      reason: json['reason'] as String?,
      installmentMonths: _parseInt(json['installment_months'], fallback: 1),
      installmentAmount: _parseDouble(json['installment_amount']),
      remainingAmount: _parseDouble(json['remaining_amount']),
      paidMonths: _parseInt(json['paid_months']),
      isFullyDeducted: json['is_fully_deducted'] as bool? ?? false,
      isDeducted: json['is_deducted'] as bool? ?? false,
      deductedAt: _parseDateTime(json['deducted_at']),
      deductedBy: json['deducted_by'] as String?,
      notes: json['notes'] as String?,
      employeeName: emp is Map ? emp['full_name'] as String? : null,
      employeeCode: emp is Map ? emp['employee_code'] as String? : null,
      // ⚠️ employees مفيش فيه main_image_url — بنسيبها null
      employeeImageUrl: null,
      createdByName: profile is Map ? profile['full_name'] as String? : null,
      createdAt: _parseDateTime(json['created_at']),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'amount': amount,
      'advance_date': advanceDate.toIso8601String().split('T').first,
      'reason': reason,
      'installment_months': installmentMonths,
      'installment_amount': installmentAmount,
      'remaining_amount': remainingAmount,
      'is_deducted': isDeducted,
      'notes': notes,
    };
  }

  AdvanceModel copyWith({
    String? id,
    String? employeeId,
    double? amount,
    DateTime? advanceDate,
    String? reason,
    int? installmentMonths,
    double? installmentAmount,
    double? remainingAmount,
    int? paidMonths,
    bool? isFullyDeducted,
    bool? isDeducted,
    DateTime? deductedAt,
    String? deductedBy,
    String? notes,
    String? employeeName,
    String? employeeCode,
    String? employeeImageUrl,
    String? createdByName,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return AdvanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      amount: amount ?? this.amount,
      advanceDate: advanceDate ?? this.advanceDate,
      reason: reason ?? this.reason,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paidMonths: paidMonths ?? this.paidMonths,
      isFullyDeducted: isFullyDeducted ?? this.isFullyDeducted,
      isDeducted: isDeducted ?? this.isDeducted,
      deductedAt: deductedAt ?? this.deductedAt,
      deductedBy: deductedBy ?? this.deductedBy,
      notes: notes ?? this.notes,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeImageUrl: employeeImageUrl ?? this.employeeImageUrl,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // ============ Getters ============
  bool get isInstallment => installmentMonths > 1;
  bool get isFullyPaid => isFullyDeducted || remainingAmount <= 0;
  int get remainingMonths => (installmentMonths - paidMonths).clamp(0, 999);
  double get paidAmount => amount - remainingAmount;
  double get progressPercent => amount <= 0 ? 0 : (paidAmount / amount) * 100;

  String get statusLabelAr {
    if (isFullyPaid) return 'مسددة';
    if (isInstallment) return 'تقسيط ($paidMonths/$installmentMonths)';
    return 'مستحقة';
  }

  // ============ Parsers ============
  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _parseInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
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

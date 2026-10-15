// lib/features/invoices/data/models/payment_model.dart

class PaymentModel {
  final String id;
  final String invoiceId;
  final double amount;
  final String method; // cash / vodafone_cash / instapay
  final DateTime paymentDate;
  final String? notes;
  final DateTime? createdAt;
  final String? createdBy;

  // علاقات
  final String? createdByName;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    this.method = 'cash',
    required this.paymentDate,
    this.notes,
    this.createdAt,
    this.createdBy,
    this.createdByName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    return PaymentModel(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      amount: _parseDouble(json['amount']),
      method: json['method'] as String? ?? 'cash',
      paymentDate: _parseDate(json['payment_date']) ?? DateTime.now(),
      notes: json['notes'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      createdBy: json['created_by'] as String?,
      createdByName: creator is Map ? creator['full_name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'amount': amount,
      'method': method,
      'payment_date': paymentDate.toIso8601String().split('T').first,
      'notes': notes,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? invoiceId,
    double? amount,
    String? method,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
    );
  }

  // =====================================================
  // Getters
  // =====================================================
  String get methodLabelAr {
    switch (method) {
      case 'cash':
        return 'كاش';
      case 'vodafone_cash':
        return 'فودافون كاش';
      case 'instapay':
        return 'إنستاباي';
      default:
        return method;
    }
  }

  // =====================================================
  // Parsers
  // =====================================================
  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
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

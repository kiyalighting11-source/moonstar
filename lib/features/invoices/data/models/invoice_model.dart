// lib/features/invoices/data/models/invoice_model.dart

import 'invoice_item_model.dart';
import 'payment_model.dart';

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String type; // sale / sale_return / quote
  final String? title; // "بيان" دائماً

  // الأطراف
  final String? customerId;
  final String? supplierId;
  final String? warehouseId;

  // المبالغ
  final double subtotal; // مجموع بنود المخزون
  final double totalExtra; // مجموع البنود الإضافية
  final double discount; // المبلغ الفعلي للخصم
  final double tax; // المبلغ الفعلي للضريبة
  final double total; // الإجمالي
  final double paidAmount;
  final double dueAmount;

  // إعدادات الخصم
  final String discountType; // fixed / percentage
  final double discountValue;

  // إعدادات الضريبة
  final String taxType; // fixed / percentage
  final double taxValue;
  final bool taxIncluded;

  // الدفع
  final String paymentMethod; // cash / vodafone_cash / instapay
  final String status; // draft / quote / confirmed / paid / partial / cancelled

  // التواريخ
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final DateTime? expectedPaymentDate;
  final DateTime? lastPaymentDate;
  final double lastPaymentAmount;

  final String? notes;

  // علاقات
  final String? customerName;
  final String? customerPhone;
  final String? supplierName;
  final String? warehouseName;
  final String? createdByName;

  // قوائم
  final List<InvoiceItemModel> items;
  final List<PaymentModel> payments;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    this.title = 'بيان',
    this.customerId,
    this.supplierId,
    this.warehouseId,
    this.subtotal = 0,
    this.totalExtra = 0,
    this.discount = 0,
    this.tax = 0,
    this.total = 0,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.discountType = 'fixed',
    this.discountValue = 0,
    this.taxType = 'fixed',
    this.taxValue = 0,
    this.taxIncluded = false,
    this.paymentMethod = 'cash',
    this.status = 'draft',
    required this.invoiceDate,
    this.dueDate,
    this.expectedPaymentDate,
    this.lastPaymentDate,
    this.lastPaymentAmount = 0,
    this.notes,
    this.customerName,
    this.customerPhone,
    this.supplierName,
    this.warehouseName,
    this.createdByName,
    this.items = const [],
    this.payments = const [],
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'];
    final supplier = json['suppliers'];
    final warehouse = json['warehouses'];
    final creator = json['creator'];

    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      type: json['type'] as String? ?? 'sale',
      title: json['title'] as String? ?? 'بيان',
      customerId: json['customer_id'] as String?,
      supplierId: json['supplier_id'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      subtotal: _parseDouble(json['subtotal']),
      totalExtra: _parseDouble(json['total_extra']),
      discount: _parseDouble(json['discount']),
      tax: _parseDouble(json['tax']),
      total: _parseDouble(json['total']),
      paidAmount: _parseDouble(json['paid_amount']),
      dueAmount: _parseDouble(json['due_amount']),
      discountType: json['discount_type'] as String? ?? 'fixed',
      discountValue: _parseDouble(json['discount_value']),
      taxType: json['tax_type'] as String? ?? 'fixed',
      taxValue: _parseDouble(json['tax_value']),
      taxIncluded: json['tax_included'] as bool? ?? false,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'draft',
      invoiceDate: _parseDate(json['invoice_date']) ?? DateTime.now(),
      dueDate: _parseDate(json['due_date']),
      expectedPaymentDate: _parseDate(json['expected_payment_date']),
      lastPaymentDate: _parseDate(json['last_payment_date']),
      lastPaymentAmount: _parseDouble(json['last_payment_amount']),
      notes: json['notes'] as String?,
      customerName: customer is Map ? customer['name'] as String? : null,
      customerPhone: customer is Map ? customer['phone'] as String? : null,
      supplierName: supplier is Map ? supplier['name'] as String? : null,
      warehouseName: warehouse is Map ? warehouse['name'] as String? : null,
      createdByName: creator is Map ? creator['full_name'] as String? : null,
      items: _parseItems(json['invoice_items']),
      payments: _parsePayments(json['payments']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'type': type,
      'title': title,
      'customer_id': customerId,
      'supplier_id': supplierId,
      'warehouse_id': warehouseId,
      'subtotal': subtotal,
      'total_extra': totalExtra,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'discount_type': discountType,
      'discount_value': discountValue,
      'tax_type': taxType,
      'tax_value': taxValue,
      'tax_included': taxIncluded,
      'payment_method': paymentMethod,
      'status': status,
      'invoice_date': invoiceDate.toIso8601String().split('T').first,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'expected_payment_date':
          expectedPaymentDate?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? type,
    String? title,
    String? customerId,
    String? supplierId,
    String? warehouseId,
    double? subtotal,
    double? totalExtra,
    double? discount,
    double? tax,
    double? total,
    double? paidAmount,
    double? dueAmount,
    String? discountType,
    double? discountValue,
    String? taxType,
    double? taxValue,
    bool? taxIncluded,
    String? paymentMethod,
    String? status,
    DateTime? invoiceDate,
    DateTime? dueDate,
    DateTime? expectedPaymentDate,
    DateTime? lastPaymentDate,
    double? lastPaymentAmount,
    String? notes,
    String? customerName,
    String? customerPhone,
    String? supplierName,
    String? warehouseName,
    String? createdByName,
    List<InvoiceItemModel>? items,
    List<PaymentModel>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool clearCustomer = false,
    bool clearSupplier = false,
    bool clearWarehouse = false,
    bool clearDueDate = false,
    bool clearExpectedDate = false,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      title: title ?? this.title,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      warehouseId: clearWarehouse ? null : (warehouseId ?? this.warehouseId),
      subtotal: subtotal ?? this.subtotal,
      totalExtra: totalExtra ?? this.totalExtra,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      taxType: taxType ?? this.taxType,
      taxValue: taxValue ?? this.taxValue,
      taxIncluded: taxIncluded ?? this.taxIncluded,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      expectedPaymentDate: clearExpectedDate
          ? null
          : (expectedPaymentDate ?? this.expectedPaymentDate),
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      lastPaymentAmount: lastPaymentAmount ?? this.lastPaymentAmount,
      notes: notes ?? this.notes,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      supplierName: supplierName ?? this.supplierName,
      warehouseName: warehouseName ?? this.warehouseName,
      createdByName: createdByName ?? this.createdByName,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // =====================================================
  // Getters
  // =====================================================
  bool get isSale => type == 'sale';
  bool get isSaleReturn => type == 'sale_return';
  bool get isQuote => type == 'quote';
  bool get isReturn => isSaleReturn;

  bool get isDraft => status == 'draft';
  bool get isConfirmed => status == 'confirmed';
  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';
  bool get isCancelled => status == 'cancelled';

  /// هل الفاتورة مكتملة الدفع؟
  bool get isFullyPaid => dueAmount <= 0.01;

  /// نسبة الخصم المعروضة
  String get discountLabel {
    if (discountValue <= 0) return '—';
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return discountValue.toStringAsFixed(0);
  }

  /// نسبة الضريبة المعروضة
  String get taxLabel {
    if (taxValue <= 0) return '—';
    if (taxType == 'percentage') {
      return '${taxValue.toStringAsFixed(0)}%';
    }
    return taxValue.toStringAsFixed(0);
  }

  String get typeLabelAr {
    switch (type) {
      case 'sale':
        return 'بيع';
      case 'sale_return':
        return 'مرتجع بيع';
      case 'quote':
        return 'عرض سعر';
      default:
        return type;
    }
  }

  String get statusLabelAr {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'quote':
        return 'عرض سعر';
      case 'confirmed':
        return 'مؤكدة';
      case 'paid':
        return 'مدفوعة';
      case 'partial':
        return 'مدفوعة جزئياً';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  String get paymentMethodLabelAr {
    switch (paymentMethod) {
      case 'cash':
        return 'كاش';
      case 'vodafone_cash':
        return 'فودافون كاش';
      case 'instapay':
        return 'إنستاباي';
      default:
        return paymentMethod;
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

  static List<InvoiceItemModel> _parseItems(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => InvoiceItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static List<PaymentModel> _parsePayments(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => PaymentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}

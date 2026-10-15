// lib/features/invoices/data/models/invoice_item_model.dart

class InvoiceItemModel {
  final String id;
  final String invoiceId;
  final String? productId;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double tax;
  final double lineTotal;
  final String? notes;

  /// ⭐ هل البند ده مربوط بالمخزون؟
  /// - true → منتج من المخزن (بيأثر على stock)
  /// - false → بند إضافي (خدمة، شحن، تركيب...)
  final bool isStockItem;

  /// اسم البند (لو مفيش product_id أو لو بند إضافي)
  final String? itemName;

  /// الوحدة (قطعة، كيلو...)
  final String? unit;

  // علاقات
  final String? productName;
  final String? productSku;
  final String? productImageUrl;

  final DateTime? createdAt;

  InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    this.productId,
    this.quantity = 1,
    this.unitPrice = 0,
    this.discount = 0,
    this.tax = 0,
    this.lineTotal = 0,
    this.notes,
    this.isStockItem = true,
    this.itemName,
    this.unit,
    this.productName,
    this.productSku,
    this.productImageUrl,
    this.createdAt,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    return InvoiceItemModel(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      productId: json['product_id'] as String?,
      quantity: _parseDouble(json['quantity']),
      unitPrice: _parseDouble(json['unit_price']),
      discount: _parseDouble(json['discount']),
      tax: _parseDouble(json['tax']),
      lineTotal: _parseDouble(json['line_total']),
      notes: json['notes'] as String?,
      isStockItem: json['is_stock_item'] as bool? ?? true,
      itemName: json['item_name'] as String?,
      unit: json['unit'] as String?,
      productName: product is Map ? product['name'] as String? : null,
      productSku: product is Map ? product['sku'] as String? : null,
      productImageUrl:
          product is Map ? product['main_image_url'] as String? : null,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'tax': tax,
      'line_total': lineTotal,
      'notes': notes,
      'is_stock_item': isStockItem,
      'item_name': itemName,
      'unit': unit,
    };
  }

  InvoiceItemModel copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    double? quantity,
    double? unitPrice,
    double? discount,
    double? tax,
    double? lineTotal,
    String? notes,
    bool? isStockItem,
    String? itemName,
    String? unit,
    String? productName,
    String? productSku,
    String? productImageUrl,
    DateTime? createdAt,
    bool clearProduct = false,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: clearProduct ? null : (productId ?? this.productId),
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      lineTotal: lineTotal ?? this.lineTotal,
      notes: notes ?? this.notes,
      isStockItem: isStockItem ?? this.isStockItem,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // =====================================================
  // Getters
  // =====================================================

  /// الاسم المعروض
  String get displayName {
    if (productName != null && productName!.isNotEmpty) {
      return productName!;
    }
    return itemName ?? 'بند';
  }

  /// السعر قبل الخصم والضريبة
  double get subtotal => quantity * unitPrice;

  /// المبلغ بعد الخصم والضريبة
  double get computedTotal {
    return (subtotal - discount) + tax;
  }

  // =====================================================
  // Parsers
  // =====================================================
  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
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

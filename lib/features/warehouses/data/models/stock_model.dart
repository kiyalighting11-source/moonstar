// lib/features/warehouses/data/models/stock_model.dart

class StockModel {
  final String id;
  final String warehouseId;
  final String productId;
  final double quantity;
  final DateTime? updatedAt;

  // علاقات
  final String? productName;
  final String? productSku;
  final String? productImageUrl;
  final int? reorderLevel;
  final String? warehouseName;

  StockModel({
    required this.id,
    required this.warehouseId,
    required this.productId,
    required this.quantity,
    this.updatedAt,
    this.productName,
    this.productSku,
    this.productImageUrl,
    this.reorderLevel,
    this.warehouseName,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    return StockModel(
      id: json['id'] as String,
      warehouseId: json['warehouse_id'] as String,
      productId: json['product_id'] as String,
      quantity: _parseDouble(json['quantity']),
      updatedAt: _parseDate(json['updated_at']),
      productName: product is Map ? product['name'] as String? : null,
      productSku: product is Map ? product['sku'] as String? : null,
      productImageUrl:
          product is Map ? product['main_image_url'] as String? : null,
      reorderLevel: product is Map ? _parseInt(product['reorder_level']) : null,
      warehouseName: json['warehouses'] is Map
          ? json['warehouses']['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'product_id': productId,
      'quantity': quantity,
    };
  }

  // هل الكمية أقل من حد إعادة الطلب؟
  bool get isLowStock {
    if (reorderLevel == null) return false;
    return quantity <= reorderLevel!;
  }

  // الحالة
  String get status {
    if (quantity <= 0) return 'out';
    if (isLowStock) return 'low';
    return 'ok';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

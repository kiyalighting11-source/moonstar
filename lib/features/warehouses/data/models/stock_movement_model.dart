// lib/features/warehouses/data/models/stock_movement_model.dart

class StockMovementModel {
  final String id;
  final String warehouseId;
  final String productId;
  final String type;
  final double quantity;
  final double? balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? note;
  final DateTime? createdAt;
  final String? createdBy;

  // علاقات
  final String? productName;
  final String? productSku;
  final String? warehouseName;
  final String? createdByName;

  StockMovementModel({
    required this.id,
    required this.warehouseId,
    required this.productId,
    required this.type,
    required this.quantity,
    this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.note,
    this.createdAt,
    this.createdBy,
    this.productName,
    this.productSku,
    this.warehouseName,
    this.createdByName,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as String,
      warehouseId: json['warehouse_id'] as String,
      productId: json['product_id'] as String,
      type: json['type'] as String? ?? 'adjustment',
      quantity: _parseDouble(json['quantity']),
      balanceAfter: json['balance_after'] != null
          ? _parseDouble(json['balance_after'])
          : null,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      note: json['note'] as String?,
      createdAt: _parseDate(json['created_at']),
      createdBy: json['created_by'] as String?,
      productName:
          json['products'] is Map ? json['products']['name'] as String? : null,
      productSku:
          json['products'] is Map ? json['products']['sku'] as String? : null,
      warehouseName: json['warehouses'] is Map
          ? json['warehouses']['name'] as String?
          : null,
      createdByName: json['profiles'] is Map
          ? json['profiles']['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'note': note,
    };
  }

  // هل الحركة إدخال؟
  bool get isIn =>
      type == 'purchase_in' || type == 'transfer_in' || type == 'return_in';

  // هل الحركة إخراج؟
  bool get isOut =>
      type == 'sale_out' ||
      type == 'transfer_out' ||
      type == 'maintenance_out' ||
      type == 'return_out';

  // اللون
  String get typeLabel {
    switch (type) {
      case 'purchase_in':
        return 'إدخال شراء';
      case 'sale_out':
        return 'إخراج بيع';
      case 'transfer_in':
        return 'تحويل داخل';
      case 'transfer_out':
        return 'تحويل خارج';
      case 'adjustment':
        return 'تسوية';
      case 'maintenance_out':
        return 'قطع صيانة';
      case 'return_in':
        return 'مرتجع داخل';
      case 'return_out':
        return 'مرتجع خارج';
      default:
        return type;
    }
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
}

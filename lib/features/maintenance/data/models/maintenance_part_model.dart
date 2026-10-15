// lib/features/maintenance/data/models/maintenance_part_model.dart

class MaintenancePartModel {
  final String id;
  final String ticketId;
  final String? deviceId; // ⭐ جديد: القطعة تابعة لأي جهاز
  final String productId;
  final double quantity;
  final double unitPrice;
  final double total;
  final String? notes;
  final DateTime? createdAt;
  final String? createdBy;

  // علاقات
  final String? productName;
  final String? productSku;
  final String? productImageUrl;

  MaintenancePartModel({
    required this.id,
    required this.ticketId,
    this.deviceId,
    required this.productId,
    this.quantity = 1,
    this.unitPrice = 0,
    this.total = 0,
    this.notes,
    this.createdAt,
    this.createdBy,
    this.productName,
    this.productSku,
    this.productImageUrl,
  });

  factory MaintenancePartModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    return MaintenancePartModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      deviceId: json['device_id'] as String?, // ⭐
      productId: json['product_id'] as String,
      quantity: _d(json['quantity']),
      unitPrice: _d(json['unit_price']),
      total: _d(json['total']),
      notes: json['notes'] as String?,
      createdAt: _dt(json['created_at']),
      createdBy: json['created_by'] as String?,
      productName: product is Map ? product['name'] as String? : null,
      productSku: product is Map ? product['sku'] as String? : null,
      productImageUrl:
          product is Map ? product['main_image_url'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'device_id': deviceId, // ⭐
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'notes': notes,
    };
  }

  MaintenancePartModel copyWith({
    String? id,
    String? ticketId,
    String? deviceId,
    String? productId,
    double? quantity,
    double? unitPrice,
    double? total,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    String? productName,
    String? productSku,
    String? productImageUrl,
    bool clearDevice = false,
  }) {
    return MaintenancePartModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      deviceId: clearDevice ? null : (deviceId ?? this.deviceId),
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      productImageUrl: productImageUrl ?? this.productImageUrl,
    );
  }

  // ============ Getters ============
  bool get hasDevice => deviceId != null;

  // ============ Parsers ============
  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}

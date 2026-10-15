// lib/features/maintenance/data/models/maintenance_device_model.dart

class MaintenanceDeviceModel {
  final String id;
  final String ticketId;
  final String? productId;
  final String? deviceDescription;
  final String? serialNumber;
  final String issueDescription;
  final String? resolution;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  // علاقات
  final String? productName;
  final String? productSku;
  final String? productImageUrl;

  MaintenanceDeviceModel({
    required this.id,
    required this.ticketId,
    this.productId,
    this.deviceDescription,
    this.serialNumber,
    required this.issueDescription,
    this.resolution,
    this.price = 0,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.productName,
    this.productSku,
    this.productImageUrl,
  });

  factory MaintenanceDeviceModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    return MaintenanceDeviceModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      productId: json['product_id'] as String?,
      deviceDescription: json['device_description'] as String?,
      serialNumber: json['serial_number'] as String?,
      issueDescription: json['issue_description'] as String? ?? '',
      resolution: json['resolution'] as String?,
      price: _d(json['price']),
      createdAt: _dt(json['created_at']),
      updatedAt: _dt(json['updated_at']),
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
      'product_id': productId,
      'device_description': deviceDescription,
      'serial_number': serialNumber,
      'issue_description': issueDescription,
      'resolution': resolution,
      'price': price,
    };
  }

  MaintenanceDeviceModel copyWith({
    String? id,
    String? ticketId,
    String? productId,
    String? deviceDescription,
    String? serialNumber,
    String? issueDescription,
    String? resolution,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? productName,
    String? productSku,
    String? productImageUrl,
    bool clearProduct = false,
  }) {
    return MaintenanceDeviceModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      productId: clearProduct ? null : (productId ?? this.productId),
      deviceDescription: deviceDescription ?? this.deviceDescription,
      serialNumber: serialNumber ?? this.serialNumber,
      issueDescription: issueDescription ?? this.issueDescription,
      resolution: resolution ?? this.resolution,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      productImageUrl: productImageUrl ?? this.productImageUrl,
    );
  }

  // ============ Getters ============
  bool get hasProduct => productId != null;

  bool get hasSerial => serialNumber != null && serialNumber!.isNotEmpty;

  String get displayName {
    if (productName != null && productName!.isNotEmpty) return productName!;
    if (deviceDescription != null && deviceDescription!.isNotEmpty) {
      return deviceDescription!;
    }
    return 'بدون وصف';
  }

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

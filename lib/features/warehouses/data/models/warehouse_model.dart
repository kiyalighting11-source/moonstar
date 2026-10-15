// lib/features/warehouses/data/models/warehouse_model.dart

class WarehouseModel {
  final String id;
  final String name;
  final String? location;
  final String? managerId;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;

  // علاقات
  final String? managerName;
  final int? productsCount;
  final double? totalQuantity;

  WarehouseModel({
    required this.id,
    required this.name,
    this.location,
    this.managerId,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.managerName,
    this.productsCount,
    this.totalQuantity,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      managerId: json['manager_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      managerName: _getManagerName(json['employees']),
      productsCount: json['products_count'] != null
          ? _parseInt(json['products_count'])
          : null,
      totalQuantity: json['total_quantity'] != null
          ? _parseDouble(json['total_quantity'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'manager_id': managerId,
      'is_active': isActive,
      'notes': notes,
    };
  }

  WarehouseModel copyWith({
    String? id,
    String? name,
    String? location,
    String? managerId,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    String? managerName,
    int? productsCount,
    double? totalQuantity,
    bool clearManager = false,
  }) {
    return WarehouseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      managerId: clearManager ? null : (managerId ?? this.managerId),
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      managerName: managerName ?? this.managerName,
      productsCount: productsCount ?? this.productsCount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static String? _getManagerName(dynamic relation) {
    if (relation == null) return null;
    if (relation is Map) return relation['full_name'] as String?;
    if (relation is List && relation.isNotEmpty) {
      final first = relation.first;
      if (first is Map) return first['full_name'] as String?;
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

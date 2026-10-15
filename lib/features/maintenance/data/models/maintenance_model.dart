// lib/features/maintenance/data/models/maintenance_model.dart

import 'maintenance_device_model.dart';
import 'maintenance_part_model.dart';

class MaintenanceModel {
  final String id;
  final String ticketNumber;

  // الأطراف
  final String customerId;
  final String? technicianId;

  // الحالة
  final String priority;
  final String status;

  // التكاليف
  final double laborCost;
  final double partsCost;
  final double totalCost;
  final double paidAmount;
  final double dueAmount;

  /// ⭐ العمود القديم (ممكن يستخدم كـ fallback)
  final double devicePriceFromColumn;

  // التواريخ
  final DateTime? receivedAt;
  final DateTime? expectedDelivery;
  final DateTime? deliveredAt;

  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  // علاقات
  final String? customerName;
  final String? customerPhone;
  final String? technicianName;
  final String? createdByName;

  // القوائم
  final List<MaintenanceDeviceModel> devices;
  final List<MaintenancePartModel> parts;

  MaintenanceModel({
    required this.id,
    required this.ticketNumber,
    required this.customerId,
    this.technicianId,
    this.priority = 'normal',
    this.status = 'new',
    this.laborCost = 0,
    this.partsCost = 0,
    this.totalCost = 0,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.devicePriceFromColumn = 0,
    this.receivedAt,
    this.expectedDelivery,
    this.deliveredAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.customerName,
    this.customerPhone,
    this.technicianName,
    this.createdByName,
    this.devices = const [],
    this.parts = const [],
  });

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'];
    final technician = json['technician'];
    final creator = json['creator'];

    return MaintenanceModel(
      id: json['id'] as String,
      ticketNumber: json['ticket_number'] as String? ?? '',
      customerId: json['customer_id'] as String,
      technicianId: json['technician_id'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'new',
      laborCost: _d(json['labor_cost']),
      partsCost: _d(json['parts_cost']),
      totalCost: _d(json['total_cost']),
      paidAmount: _d(json['paid_amount']),
      dueAmount: _d(json['due_amount']),
      devicePriceFromColumn: _d(json['device_price']),
      receivedAt: _dt(json['received_at']),
      expectedDelivery: _dt(json['expected_delivery']),
      deliveredAt: _dt(json['delivered_at']),
      notes: json['notes'] as String?,
      createdAt: _dt(json['created_at']),
      updatedAt: _dt(json['updated_at']),
      createdBy: json['created_by'] as String?,
      customerName: customer is Map ? customer['name'] as String? : null,
      customerPhone: customer is Map ? customer['phone'] as String? : null,
      technicianName:
          technician is Map ? technician['full_name'] as String? : null,
      createdByName: creator is Map ? creator['full_name'] as String? : null,
      devices: _parseDevices(json['maintenance_devices']),
      parts: _parseParts(json['maintenance_parts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'technician_id': technicianId,
      'priority': priority,
      'status': status,
      'labor_cost': laborCost,
      'expected_delivery': expectedDelivery?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }

  MaintenanceModel copyWith({
    String? id,
    String? ticketNumber,
    String? customerId,
    String? technicianId,
    String? priority,
    String? status,
    double? laborCost,
    double? partsCost,
    double? totalCost,
    double? paidAmount,
    double? dueAmount,
    double? devicePriceFromColumn,
    DateTime? receivedAt,
    DateTime? expectedDelivery,
    DateTime? deliveredAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? customerName,
    String? customerPhone,
    String? technicianName,
    String? createdByName,
    List<MaintenanceDeviceModel>? devices,
    List<MaintenancePartModel>? parts,
    bool clearTechnician = false,
    bool clearExpectedDelivery = false,
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      customerId: customerId ?? this.customerId,
      technicianId:
          clearTechnician ? null : (technicianId ?? this.technicianId),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      laborCost: laborCost ?? this.laborCost,
      partsCost: partsCost ?? this.partsCost,
      totalCost: totalCost ?? this.totalCost,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      devicePriceFromColumn:
          devicePriceFromColumn ?? this.devicePriceFromColumn,
      receivedAt: receivedAt ?? this.receivedAt,
      expectedDelivery: clearExpectedDelivery
          ? null
          : (expectedDelivery ?? this.expectedDelivery),
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      technicianName: technicianName ?? this.technicianName,
      createdByName: createdByName ?? this.createdByName,
      devices: devices ?? this.devices,
      parts: parts ?? this.parts,
    );
  }

  // ============ Getters ============
  bool get hasTechnician => technicianId != null;
  bool get hasDevices => devices.isNotEmpty;
  bool get hasParts => parts.isNotEmpty;
  bool get isFullyPaid => dueAmount <= 0.01;

  int get devicesCount => devices.length;
  int get partsCount => parts.length;

  /// ⭐ إجمالي أسعار الأجهزة
  /// - بنحسبها من قائمة الأجهزة (الأدق)
  /// - لو مفيش أجهزة في القائمة، نستخدم العمود القديم (fallback)
  double get devicesPrice {
    if (devices.isNotEmpty) {
      double total = 0;
      for (final d in devices) {
        total += d.price;
      }
      return total;
    }
    return devicePriceFromColumn;
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

  static List<MaintenanceDeviceModel> _parseDevices(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => MaintenanceDeviceModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }
    return [];
  }

  static List<MaintenancePartModel> _parseParts(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) =>
              MaintenancePartModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}

// lib/features/customers/data/models/customer_model.dart

class CustomerModel {
  final String id;
  final String code;
  final String name;
  final String type; // individual / company
  final String? phone;
  final String? phone2;
  final String? email;
  final String? address;
  final String? taxNumber;
  final double balance;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerModel({
    required this.id,
    required this.code,
    required this.name,
    this.type = 'individual',
    this.phone,
    this.phone2,
    this.email,
    this.address,
    this.taxNumber,
    this.balance = 0,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'individual',
      phone: json['phone'] as String?,
      phone2: json['phone2'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      taxNumber: json['tax_number'] as String?,
      balance: _parseDouble(json['balance']),
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'phone': phone,
      'phone2': phone2,
      'email': email,
      'address': address,
      'tax_number': taxNumber,
      'balance': balance,
      'notes': notes,
      'is_active': isActive,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? code,
    String? name,
    String? type,
    String? phone,
    String? phone2,
    String? email,
    String? address,
    String? taxNumber,
    double? balance,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      balance: balance ?? this.balance,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // هل العميل شركة؟
  bool get isCompany => type == 'company';

  // هل عنده رصيد؟
  bool get hasBalance => balance != 0;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

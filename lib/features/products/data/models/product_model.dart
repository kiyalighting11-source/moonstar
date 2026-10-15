// lib/features/products/data/models/product_model.dart

class ProductModel {
  final String id;
  final String sku;
  final String name;
  final String? description;
  final String? categoryId;
  final String unit;
  final double price;
  final double purchasePrice;
  final int reorderLevel;
  final String? mainImageUrl;
  final List<String> galleryImages;
  final String? videoUrl;

  // Stage Lighting
  final String? voltage;
  final String? powerWatts;
  final String? lumens;
  final String? colorTemp;
  final String? beamAngle;

  // LED Screen
  final String? pixelPitch;
  final String? brightness;
  final String? refreshRate;
  final String? viewingAngle;

  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? categoryName;
  final String? categoryParentName;

  ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    this.categoryId,
    this.unit = 'قطعة',
    this.price = 0,
    this.purchasePrice = 0,
    this.reorderLevel = 10,
    this.mainImageUrl,
    this.galleryImages = const [],
    this.videoUrl,
    this.voltage,
    this.powerWatts,
    this.lumens,
    this.colorTemp,
    this.beamAngle,
    this.pixelPitch,
    this.brightness,
    this.refreshRate,
    this.viewingAngle,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.categoryParentName,
  });

  // =====================================================
  // من جدول products (للموظفين المسجلين)
  // =====================================================
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      unit: json['unit'] as String? ?? 'قطعة',
      price: _parseDouble(json['price']),
      purchasePrice: _parseDouble(json['purchase_price']),
      reorderLevel: _parseInt(json['reorder_level']),
      mainImageUrl: json['main_image_url'] as String?,
      galleryImages: _parseStringList(json['gallery_images']),
      videoUrl: json['video_url'] as String?,
      voltage: json['voltage'] as String?,
      powerWatts: json['power_watts'] as String?,
      lumens: json['lumens'] as String?,
      colorTemp: json['color_temp'] as String?,
      beamAngle: json['beam_angle'] as String?,
      pixelPitch: json['pixel_pitch'] as String?,
      brightness: json['brightness'] as String?,
      refreshRate: json['refresh_rate'] as String?,
      viewingAngle: json['viewing_angle'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      categoryName: _getRelationField(json['categories'], 'name'),
      categoryParentName: _getRelationField(
        json['categories']?['parent'],
        'name',
      ),
    );
  }

  // =====================================================
  // ⭐ من View العام public_products (للزوار)
  // - مفيش سعر، سعر شراء، أو حد إعادة طلب
  // - بنحطهم 0 عشان الكود ما يقعش
  // =====================================================
  factory ProductModel.fromPublicJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      unit: json['unit'] as String? ?? 'قطعة',
      price: 0, // ⭐ مخفي عن الزائر
      purchasePrice: 0, // ⭐ مخفي
      reorderLevel: 0, // ⭐ مخفي
      mainImageUrl: json['main_image_url'] as String?,
      galleryImages: _parseStringList(json['gallery_images']),
      videoUrl: json['video_url'] as String?,
      voltage: json['voltage'] as String?,
      powerWatts: json['power_watts'] as String?,
      lumens: json['lumens'] as String?,
      colorTemp: json['color_temp'] as String?,
      beamAngle: json['beam_angle'] as String?,
      pixelPitch: json['pixel_pitch'] as String?,
      brightness: json['brightness'] as String?,
      refreshRate: json['refresh_rate'] as String?,
      viewingAngle: json['viewing_angle'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      categoryName: _getRelationField(json['categories'], 'name'),
      categoryParentName: _getRelationField(
        json['categories']?['parent'],
        'name',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sku.isNotEmpty) 'sku': sku,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'unit': unit,
      'price': price,
      'purchase_price': purchasePrice,
      'reorder_level': reorderLevel,
      'main_image_url': mainImageUrl,
      'gallery_images': galleryImages,
      'video_url': videoUrl,
      'voltage': voltage,
      'power_watts': powerWatts,
      'lumens': lumens,
      'color_temp': colorTemp,
      'beam_angle': beamAngle,
      'pixel_pitch': pixelPitch,
      'brightness': brightness,
      'refresh_rate': refreshRate,
      'viewing_angle': viewingAngle,
      'is_active': isActive,
      'notes': notes,
    };
  }

  ProductModel copyWith({
    String? id,
    String? sku,
    String? name,
    String? description,
    String? categoryId,
    String? unit,
    double? price,
    double? purchasePrice,
    int? reorderLevel,
    String? mainImageUrl,
    List<String>? galleryImages,
    String? videoUrl,
    String? voltage,
    String? powerWatts,
    String? lumens,
    String? colorTemp,
    String? beamAngle,
    String? pixelPitch,
    String? brightness,
    String? refreshRate,
    String? viewingAngle,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryParentName,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      videoUrl: videoUrl ?? this.videoUrl,
      voltage: voltage ?? this.voltage,
      powerWatts: powerWatts ?? this.powerWatts,
      lumens: lumens ?? this.lumens,
      colorTemp: colorTemp ?? this.colorTemp,
      beamAngle: beamAngle ?? this.beamAngle,
      pixelPitch: pixelPitch ?? this.pixelPitch,
      brightness: brightness ?? this.brightness,
      refreshRate: refreshRate ?? this.refreshRate,
      viewingAngle: viewingAngle ?? this.viewingAngle,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryParentName: categoryParentName ?? this.categoryParentName,
    );
  }

  // ============ Getters ============
  double get profitMargin {
    if (price <= 0 || purchasePrice <= 0) return 0;
    return ((price - purchasePrice) / price) * 100;
  }

  double get profitPerUnit => price - purchasePrice;

  bool get hasPurchasePrice => purchasePrice > 0;

  // ============ Parsers ============
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static String? _getRelationField(dynamic relation, String field) {
    if (relation == null) return null;
    if (relation is Map) return relation[field] as String?;
    if (relation is List && relation.isNotEmpty) {
      final first = relation.first;
      if (first is Map) return first[field] as String?;
    }
    return null;
  }
}

// lib/features/reports/data/models/top_product_model.dart

class TopProductModel {
  final String productId;
  final String productName;
  final String? productSku;
  final String? productImageUrl;
  final double totalQuantity;
  final double totalRevenue;
  final int ordersCount;

  TopProductModel({
    required this.productId,
    required this.productName,
    this.productSku,
    this.productImageUrl,
    this.totalQuantity = 0,
    this.totalRevenue = 0,
    this.ordersCount = 0,
  });

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    return TopProductModel(
      productId: (json['product_id'] ?? product?['id']) as String? ?? '',
      productName: (product?['name'] ?? json['product_name']) as String? ?? '',
      productSku: (product?['sku'] ?? json['sku']) as String?,
      productImageUrl:
          (product?['main_image_url'] ?? json['main_image_url']) as String?,
      totalQuantity: _d(json['total_quantity']),
      totalRevenue: _d(json['total_revenue']),
      ordersCount: _i(json['orders_count']),
    );
  }

  /// متوسط سعر البيع
  double get averagePrice =>
      totalQuantity == 0 ? 0 : totalRevenue / totalQuantity;

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

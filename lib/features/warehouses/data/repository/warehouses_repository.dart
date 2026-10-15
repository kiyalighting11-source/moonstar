// lib/features/warehouses/data/repository/warehouses_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/stock_model.dart';
import '../models/stock_movement_model.dart';
import '../models/warehouse_model.dart';

class WarehousesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // WAREHOUSES
  // =====================================================

  Future<List<WarehouseModel>> getAllWarehouses({
    bool onlyActive = false,
  }) async {
    var query = _supabase
        .from(AppConstants.warehousesTable)
        .select('*, employees!manager_id (full_name)');

    if (onlyActive) query = query.eq('is_active', true);

    final data = await query.order('name');
    return (data as List).map((e) => WarehouseModel.fromJson(e)).toList();
  }

  Future<WarehouseModel?> getWarehouseById(String id) async {
    final data = await _supabase
        .from(AppConstants.warehousesTable)
        .select('*, employees!manager_id (full_name)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return WarehouseModel.fromJson(data);
  }

  Future<WarehouseModel> createWarehouse(WarehouseModel warehouse) async {
    final data = await _supabase
        .from(AppConstants.warehousesTable)
        .insert(warehouse.toJson())
        .select('*, employees!manager_id (full_name)')
        .single();

    return WarehouseModel.fromJson(data);
  }

  Future<WarehouseModel> updateWarehouse(WarehouseModel warehouse) async {
    final data = await _supabase
        .from(AppConstants.warehousesTable)
        .update(warehouse.toJson())
        .eq('id', warehouse.id)
        .select('*, employees!manager_id (full_name)')
        .single();

    return WarehouseModel.fromJson(data);
  }

  Future<void> toggleWarehouseStatus(String id, bool isActive) async {
    await _supabase
        .from(AppConstants.warehousesTable)
        .update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deleteWarehouse(String id) async {
    await _supabase.from(AppConstants.warehousesTable).delete().eq('id', id);
  }

  // =====================================================
  // STOCK
  // =====================================================

  /// كل المخزون في مخزن معين
  Future<List<StockModel>> getStockByWarehouse(
    String warehouseId, {
    String? search,
    bool onlyLowStock = false,
  }) async {
    final data = await _supabase
        .from(AppConstants.stockTable)
        .select(
            '*, products!product_id (name, sku, main_image_url, reorder_level)')
        .eq('warehouse_id', warehouseId)
        .order('updated_at', ascending: false);

    var stocks = (data as List).map((e) => StockModel.fromJson(e)).toList();

    // بحث محلي
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      stocks = stocks.where((s) {
        final name = s.productName?.toLowerCase() ?? '';
        final sku = s.productSku?.toLowerCase() ?? '';
        return name.contains(q) || sku.contains(q);
      }).toList();
    }

    // فلتر الكمية القليلة
    if (onlyLowStock) {
      stocks = stocks.where((s) => s.isLowStock || s.quantity <= 0).toList();
    }

    return stocks;
  }

  /// كل المخزون لكل المنتجات (الإجمالي)
  Future<List<StockModel>> getAllStock({String? search}) async {
    final data = await _supabase.from(AppConstants.stockTable).select(
        '*, products!product_id (name, sku, main_image_url, reorder_level), warehouses!warehouse_id (name)');

    var stocks = (data as List).map((e) => StockModel.fromJson(e)).toList();

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      stocks = stocks.where((s) {
        final name = s.productName?.toLowerCase() ?? '';
        final sku = s.productSku?.toLowerCase() ?? '';
        return name.contains(q) || sku.contains(q);
      }).toList();
    }

    return stocks;
  }

  /// مخزون منتج معين في كل المخازن
  Future<List<StockModel>> getStockByProduct(String productId) async {
    final data = await _supabase
        .from(AppConstants.stockTable)
        .select(
            '*, products!product_id (name, sku, main_image_url, reorder_level), warehouses!warehouse_id (name)')
        .eq('product_id', productId);

    return (data as List).map((e) => StockModel.fromJson(e)).toList();
  }

  /// إجمالي كمية منتج (في كل المخازن)
  Future<double> getTotalQuantityByProduct(String productId) async {
    final data = await _supabase
        .from(AppConstants.stockTable)
        .select('quantity')
        .eq('product_id', productId);

    final list = data as List;
    double total = 0;
    for (final item in list) {
      total += (item['quantity'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// المنتجات القليلة (من الـ view v_low_stock)
  Future<List<StockModel>> getLowStockItems() async {
    final data = await _supabase.from('v_low_stock').select('*');

    return (data as List).map((e) {
      return StockModel(
        id: e['stock_id'] as String,
        warehouseId: e['warehouse_id'] as String,
        productId: e['product_id'] as String,
        quantity: (e['current_quantity'] as num?)?.toDouble() ?? 0,
        productName: e['product_name'] as String?,
        productSku: e['sku'] as String?,
        productImageUrl: e['main_image_url'] as String?,
        reorderLevel: (e['reorder_level'] as num?)?.toInt(),
        warehouseName: e['warehouse_name'] as String?,
        updatedAt: e['updated_at'] != null
            ? DateTime.tryParse(e['updated_at'].toString())
            : null,
      );
    }).toList();
  }

  // =====================================================
  // STOCK MOVEMENTS
  // =====================================================

  Future<List<StockMovementModel>> getMovements({
    String? warehouseId,
    String? productId,
    String? type,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) async {
    var query = _supabase.from(AppConstants.stockMovementsTable).select(
        '*, products!product_id (name, sku), warehouses!warehouse_id (name), profiles!created_by (full_name)');

    if (warehouseId != null) query = query.eq('warehouse_id', warehouseId);
    if (productId != null) query = query.eq('product_id', productId);
    if (type != null) query = query.eq('type', type);
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final data = await query.order('created_at', ascending: false).limit(limit);

    return (data as List).map((e) => StockMovementModel.fromJson(e)).toList();
  }

  /// إضافة حركة مخزون (الـ Trigger هيحدث stock)
  Future<StockMovementModel> createMovement(
    StockMovementModel movement,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    final data = await _supabase
        .from(AppConstants.stockMovementsTable)
        .insert({
          ...movement.toJson(),
          'created_by': userId,
        })
        .select()
        .single();

    return StockMovementModel.fromJson(data);
  }

  // =====================================================
  // STOCK COUNT (الجرد)
  // =====================================================

  /// حفظ الجرد (تسوية كل الفروقات)
  Future<void> saveStockCount({
    required String warehouseId,
    required Map<String, double> actualQuantities,
    String? note,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    // نجيب الكميات الحالية
    final currentData = await _supabase
        .from(AppConstants.stockTable)
        .select('product_id, quantity')
        .eq('warehouse_id', warehouseId);

    final currentMap = <String, double>{};
    for (final item in (currentData as List)) {
      currentMap[item['product_id'] as String] =
          (item['quantity'] as num?)?.toDouble() ?? 0;
    }

    // نضيف adjustment لكل منتج فيه فرق
    final movementsToAdd = <Map<String, dynamic>>[];

    for (final entry in actualQuantities.entries) {
      final productId = entry.key;
      final actual = entry.value;
      final current = currentMap[productId] ?? 0;
      final diff = actual - current;

      if (diff.abs() > 0.001) {
        movementsToAdd.add({
          'warehouse_id': warehouseId,
          'product_id': productId,
          'type': 'adjustment',
          'quantity': diff,
          'note': note ?? 'تسوية جرد',
          'created_by': userId,
        });
      }
    }

    if (movementsToAdd.isNotEmpty) {
      await _supabase
          .from(AppConstants.stockMovementsTable)
          .insert(movementsToAdd);
    }
  }
}

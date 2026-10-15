// lib/features/warehouses/data/providers/warehouses_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stock_model.dart';
import '../models/stock_movement_model.dart';
import '../models/warehouse_model.dart';
import '../repository/warehouses_repository.dart';

// =====================================================
// Repository
// =====================================================
final warehousesRepositoryProvider = Provider<WarehousesRepository>((ref) {
  return WarehousesRepository();
});

// =====================================================
// قائمة المخازن
// =====================================================
final warehousesListProvider =
    FutureProvider.autoDispose<List<WarehouseModel>>((ref) async {
  final repo = ref.watch(warehousesRepositoryProvider);
  return await repo.getAllWarehouses();
});

// =====================================================
// مخزن واحد
// =====================================================
final warehouseByIdProvider =
    FutureProvider.autoDispose.family<WarehouseModel?, String>((ref, id) async {
  final repo = ref.watch(warehousesRepositoryProvider);
  return await repo.getWarehouseById(id);
});

// =====================================================
// المخزون في مخزن (مع بحث)
// =====================================================
class StockFilter {
  final String? search;
  final bool onlyLowStock;

  const StockFilter({this.search, this.onlyLowStock = false});

  StockFilter copyWith({
    String? search,
    bool? onlyLowStock,
    bool clearSearch = false,
  }) {
    return StockFilter(
      search: clearSearch ? null : (search ?? this.search),
      onlyLowStock: onlyLowStock ?? this.onlyLowStock,
    );
  }
}

final stockFilterProvider = StateProvider<StockFilter>((ref) {
  return const StockFilter();
});

final stockByWarehouseProvider = FutureProvider.autoDispose
    .family<List<StockModel>, String>((ref, warehouseId) async {
  final repo = ref.watch(warehousesRepositoryProvider);
  final filter = ref.watch(stockFilterProvider);

  return await repo.getStockByWarehouse(
    warehouseId,
    search: filter.search,
    onlyLowStock: filter.onlyLowStock,
  );
});

// =====================================================
// كل المخزون (إجمالي)
// =====================================================
final allStockProvider =
    FutureProvider.autoDispose<List<StockModel>>((ref) async {
  final repo = ref.watch(warehousesRepositoryProvider);
  return await repo.getAllStock();
});

// =====================================================
// مخزون منتج
// =====================================================
final stockByProductProvider = FutureProvider.autoDispose
    .family<List<StockModel>, String>((ref, productId) async {
  final repo = ref.watch(warehousesRepositoryProvider);
  return await repo.getStockByProduct(productId);
});

// =====================================================
// إجمالي كمية منتج
// =====================================================
final totalQuantityByProductProvider =
    FutureProvider.autoDispose.family<double, String>((ref, productId) async {
  final repo = ref.watch(warehousesRepositoryProvider);
  return await repo.getTotalQuantityByProduct(productId);
});

// =====================================================
// المخزون القليل
// =====================================================
final lowStockProvider =
    FutureProvider.autoDispose<List<StockModel>>((ref) async {
  final repo = ref.watch(warehousesRepositoryProvider);
  return await repo.getLowStockItems();
});

// =====================================================
// حركات المخزون
// =====================================================
class MovementsFilter {
  final String? warehouseId;
  final String? productId;
  final String? type;
  final DateTime? fromDate;
  final DateTime? toDate;

  const MovementsFilter({
    this.warehouseId,
    this.productId,
    this.type,
    this.fromDate,
    this.toDate,
  });

  MovementsFilter copyWith({
    String? warehouseId,
    String? productId,
    String? type,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearWarehouse = false,
    bool clearProduct = false,
    bool clearType = false,
    bool clearDates = false,
  }) {
    return MovementsFilter(
      warehouseId: clearWarehouse ? null : (warehouseId ?? this.warehouseId),
      productId: clearProduct ? null : (productId ?? this.productId),
      type: clearType ? null : (type ?? this.type),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
    );
  }
}

final movementsFilterProvider = StateProvider<MovementsFilter>((ref) {
  return const MovementsFilter();
});

final movementsListProvider =
    FutureProvider.autoDispose<List<StockMovementModel>>((ref) async {
  final repo = ref.watch(warehousesRepositoryProvider);
  final filter = ref.watch(movementsFilterProvider);

  return await repo.getMovements(
    warehouseId: filter.warehouseId,
    productId: filter.productId,
    type: filter.type,
    fromDate: filter.fromDate,
    toDate: filter.toDate,
  );
});

// =====================================================
// Controller
// =====================================================
class WarehousesController extends StateNotifier<AsyncValue<void>> {
  WarehousesController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final WarehousesRepository _repo;
  final Ref _ref;

  Future<bool> createWarehouse(WarehouseModel warehouse) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createWarehouse(warehouse);
      state = const AsyncValue.data(null);
      _ref.invalidate(warehousesListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateWarehouse(WarehouseModel warehouse) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateWarehouse(warehouse);
      state = const AsyncValue.data(null);
      _ref.invalidate(warehousesListProvider);
      _ref.invalidate(warehouseByIdProvider(warehouse.id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleStatus(String id, bool isActive) async {
    try {
      await _repo.toggleWarehouseStatus(id, isActive);
      _ref.invalidate(warehousesListProvider);
      _ref.invalidate(warehouseByIdProvider(id));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWarehouse(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteWarehouse(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(warehousesListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createMovement(StockMovementModel movement) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createMovement(movement);
      state = const AsyncValue.data(null);
      _ref.invalidate(movementsListProvider);
      _ref.invalidate(stockByWarehouseProvider(movement.warehouseId));
      _ref.invalidate(allStockProvider);
      _ref.invalidate(lowStockProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> saveStockCount({
    required String warehouseId,
    required Map<String, double> actualQuantities,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveStockCount(
        warehouseId: warehouseId,
        actualQuantities: actualQuantities,
        note: note,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(stockByWarehouseProvider(warehouseId));
      _ref.invalidate(allStockProvider);
      _ref.invalidate(movementsListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final warehousesControllerProvider =
    StateNotifierProvider<WarehousesController, AsyncValue<void>>((ref) {
  return WarehousesController(ref.read(warehousesRepositoryProvider), ref);
});

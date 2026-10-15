// lib/features/admin/data/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================
// Dashboard Stats Model
// =====================================================
class DashboardStats {
  final int productsCount;
  final int warehousesCount;
  final int customersCount;
  final int invoicesCount;
  final int employeesCount;
  final int lowStockCount;
  final double totalStockQuantity;

  DashboardStats({
    this.productsCount = 0,
    this.warehousesCount = 0,
    this.customersCount = 0,
    this.invoicesCount = 0,
    this.employeesCount = 0,
    this.lowStockCount = 0,
    this.totalStockQuantity = 0,
  });
}

// =====================================================
// Dashboard Provider
// =====================================================
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final supabase = Supabase.instance.client;

  // =====================================================
  // ⭐ كل استعلام مستقل — لو واحد فشل الباقي يكمل
  // =====================================================

  final products = await _safeCount(
    () => supabase.from('products').select('id').count(),
  );

  final warehouses = await _safeCount(
    () =>
        supabase.from('warehouses').select('id').eq('is_active', true).count(),
  );

  final customers = await _safeCount(
    () => supabase.from('customers').select('id').count(),
  );

  final invoices = await _safeCount(
    () => supabase.from('invoices').select('id').count(),
  );

  final employees = await _safeCount(
    () => supabase.from('employees').select('id').eq('is_active', true).count(),
  );

  // =====================================================
  // ⭐ نحسب low stock يدوياً بدل الـ view v_low_stock
  // =====================================================
  int lowStock = 0;
  double totalQty = 0;

  try {
    final stockData = await supabase
        .from('stock')
        .select('quantity, products!product_id (reorder_level)');

    for (final item in (stockData as List)) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;

      // إجمالي المخزون
      totalQty += qty;

      // المنتج القليل
      final product = item['products'];
      final reorder = product is Map
          ? (product['reorder_level'] as num?)?.toInt() ?? 10
          : 10;

      if (qty <= reorder) lowStock++;
    }
  } catch (_) {
    // لو فشل استعلام stock، نسيب القيم الافتراضية (0)
  }

  return DashboardStats(
    productsCount: products,
    warehousesCount: warehouses,
    customersCount: customers,
    invoicesCount: invoices,
    employeesCount: employees,
    lowStockCount: lowStock,
    totalStockQuantity: totalQty,
  );
});

// =====================================================
// Helper: بيرجع العدد، ولو حصل error يرجع 0 بدل ما يرمي
// =====================================================
Future<int> _safeCount(
  Future<PostgrestResponse<dynamic>> Function() fn,
) async {
  try {
    final res = await fn();
    return res.count;
  } catch (_) {
    return 0;
  }
}

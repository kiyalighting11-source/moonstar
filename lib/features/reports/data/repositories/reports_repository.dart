// lib/features/reports/data/repositories/reports_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/sales_chart_data.dart';
import '../models/sales_summary_model.dart';
import '../models/top_product_model.dart';

class ReportsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // الملخص العام
  // =====================================================

  Future<SalesSummaryModel> getSalesSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .select('''
          total,
          paid_amount,
          due_amount,
          discount,
          tax,
          status
        ''')
        .eq('type', 'sale')
        .gte('invoice_date', _fmt(fromDate))
        .lte('invoice_date', _fmt(toDate));

    double totalSales = 0.0;
    double totalPaid = 0.0;
    double totalDue = 0.0;
    double totalDiscount = 0.0;
    double totalTax = 0.0;
    int invoicesCount = 0;
    int paidCount = 0;
    int partialCount = 0;
    int cancelledCount = 0;

    for (final row in (data as List)) {
      final status = row['status'] as String? ?? '';

      if (status == 'cancelled') {
        cancelledCount++;
        continue;
      }

      if (status == 'draft' || status == 'quote') continue;

      invoicesCount++;
      totalSales += (row['total'] as num?)?.toDouble() ?? 0.0;
      totalPaid += (row['paid_amount'] as num?)?.toDouble() ?? 0.0;
      totalDue += (row['due_amount'] as num?)?.toDouble() ?? 0.0;
      totalDiscount += (row['discount'] as num?)?.toDouble() ?? 0.0;
      totalTax += (row['tax'] as num?)?.toDouble() ?? 0.0;

      if (status == 'paid') paidCount++;
      if (status == 'partial') partialCount++;
    }

    return SalesSummaryModel(
      totalSales: totalSales,
      totalPaid: totalPaid,
      totalDue: totalDue,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      invoicesCount: invoicesCount,
      paidCount: paidCount,
      partialCount: partialCount,
      cancelledCount: cancelledCount,
    );
  }

  Future<SalesSummaryModel> getTodaySummary() {
    final now = DateTime.now();
    return getSalesSummary(
      fromDate: DateTime(now.year, now.month, now.day),
      toDate: now,
    );
  }

  Future<SalesSummaryModel> getMonthSummary() {
    final now = DateTime.now();
    return getSalesSummary(
      fromDate: DateTime(now.year, now.month, 1),
      toDate: now,
    );
  }

  Future<SalesSummaryModel> getYearSummary() {
    final now = DateTime.now();
    return getSalesSummary(
      fromDate: DateTime(now.year, 1, 1),
      toDate: now,
    );
  }

  Future<Map<String, SalesSummaryModel>> getMonthComparison() async {
    final now = DateTime.now();

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonth = await getSalesSummary(
      fromDate: thisMonthStart,
      toDate: now,
    );

    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    final lastMonth = await getSalesSummary(
      fromDate: lastMonthStart,
      toDate: lastMonthEnd,
    );

    return <String, SalesSummaryModel>{
      'this_month': thisMonth,
      'last_month': lastMonth,
    };
  }

  // =====================================================
  // الرسوم البيانية
  // =====================================================

  Future<SalesChartData> getDailySalesChart({int days = 30}) async {
    final now = DateTime.now();
    final fromDate = now.subtract(Duration(days: days));

    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .select('invoice_date, total, status')
        .eq('type', 'sale')
        .inFilter('status', ['confirmed', 'paid', 'partial'])
        .gte('invoice_date', _fmt(fromDate))
        .lte('invoice_date', _fmt(now))
        .order('invoice_date', ascending: true);

    final Map<String, SalesChartPoint> grouped = {};

    for (final row in (data as List)) {
      final dateStr = row['invoice_date'] as String? ?? '';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;

      if (grouped.containsKey(dateStr)) {
        final old = grouped[dateStr]!;
        grouped[dateStr] = SalesChartPoint(
          date: old.date,
          value: old.value + total,
          count: old.count + 1,
        );
      } else {
        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = now;
        }
        grouped[dateStr] = SalesChartPoint(
          date: date,
          value: total,
          count: 1,
        );
      }
    }

    final points = <SalesChartPoint>[];
    for (int i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = _fmt(d);
      if (grouped.containsKey(key)) {
        points.add(grouped[key]!);
      } else {
        points.add(SalesChartPoint(date: d, value: 0.0, count: 0));
      }
    }

    return SalesChartData(points: points, label: 'يومي');
  }

  Future<SalesChartData> getMonthlySalesChart({int months = 12}) async {
    final now = DateTime.now();
    final fromDate = DateTime(now.year, now.month - months + 1, 1);

    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .select('invoice_date, total')
        .eq('type', 'sale')
        .inFilter('status', ['confirmed', 'paid', 'partial'])
        .gte('invoice_date', _fmt(fromDate))
        .lte('invoice_date', _fmt(now));

    final Map<String, double> monthlyTotals = {};
    final Map<String, int> monthlyCounts = {};

    for (final row in (data as List)) {
      final dateStr = row['invoice_date'] as String? ?? '';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;

      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        continue;
      }

      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyTotals[key] = (monthlyTotals[key] ?? 0.0) + total;
      monthlyCounts[key] = (monthlyCounts[key] ?? 0) + 1;
    }

    final points = <SalesChartPoint>[];
    for (int i = months - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      points.add(SalesChartPoint(
        date: d,
        value: monthlyTotals[key] ?? 0.0,
        count: monthlyCounts[key] ?? 0,
      ));
    }

    return SalesChartData(points: points, label: 'شهري');
  }

  // =====================================================
  // الأكثر مبيعاً
  // =====================================================

  Future<List<TopProductModel>> getTopProducts({
    required DateTime fromDate,
    required DateTime toDate,
    int limit = 10,
  }) async {
    final invoiceIds = await _getInvoiceIdsInPeriod(fromDate, toDate);
    if (invoiceIds.isEmpty) return [];

    final data = await _supabase.from(AppConstants.invoiceItemsTable).select('''
          product_id,
          quantity,
          unit_price,
          line_total,
          products!product_id (id, name, sku, main_image_url)
        ''').inFilter('invoice_id', invoiceIds).eq('is_stock_item', true);

    final Map<String, TopProductModel> grouped = {};

    for (final row in (data as List)) {
      final productId = row['product_id'] as String?;
      if (productId == null) continue;

      final qty = (row['quantity'] as num?)?.toDouble() ?? 0.0;
      final total = (row['line_total'] as num?)?.toDouble() ?? 0.0;

      if (grouped.containsKey(productId)) {
        final old = grouped[productId]!;
        grouped[productId] = TopProductModel(
          productId: old.productId,
          productName: old.productName,
          productSku: old.productSku,
          productImageUrl: old.productImageUrl,
          totalQuantity: old.totalQuantity + qty,
          totalRevenue: old.totalRevenue + total,
          ordersCount: old.ordersCount + 1,
        );
      } else {
        grouped[productId] = TopProductModel.fromJson(row);
      }
    }

    final list = grouped.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return list.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getTopCustomers({
    required DateTime fromDate,
    required DateTime toDate,
    int limit = 10,
  }) async {
    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .select('''
          customer_id,
          total,
          customers!customer_id (id, name, phone, code)
        ''')
        .eq('type', 'sale')
        .inFilter('status', ['confirmed', 'paid', 'partial'])
        .gte('invoice_date', _fmt(fromDate))
        .lte('invoice_date', _fmt(toDate));

    final Map<String, Map<String, dynamic>> grouped = {};

    for (final row in (data as List)) {
      final customerId = row['customer_id'] as String?;
      if (customerId == null) continue;

      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final customer = row['customers'];

      if (grouped.containsKey(customerId)) {
        final old = grouped[customerId]!;
        old['total_sales'] = (old['total_sales'] as double) + total;
        old['invoices_count'] = (old['invoices_count'] as int) + 1;
      } else {
        grouped[customerId] = {
          'customer_id': customerId,
          'customer_name': customer is Map ? customer['name'] : 'بدون اسم',
          'phone': customer is Map ? customer['phone'] : null,
          'code': customer is Map ? customer['code'] : null,
          'total_sales': total,
          'invoices_count': 1,
        };
      }
    }

    final list = grouped.values.toList()
      ..sort((a, b) =>
          (b['total_sales'] as double).compareTo(a['total_sales'] as double));

    return list.take(limit).toList();
  }

  // =====================================================
  // الأرباح — ⭐ الإصلاح: استخدام purchase_price
  // =====================================================

  /// أرباح الفترة (المبيعات - تكلفة الشراء)
  /// ⭐ بتحسب تكلفة كل منتج = الكمية × سعر الشراء
  Future<Map<String, double>> getProfit({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final invoiceIds = await _getInvoiceIdsInPeriod(fromDate, toDate);
    if (invoiceIds.isEmpty) {
      return <String, double>{
        'revenue': 0.0,
        'cost': 0.0,
        'profit': 0.0,
        'margin': 0.0,
      };
    }

    final data = await _supabase.from(AppConstants.invoiceItemsTable).select('''
          quantity, 
          unit_price, 
          line_total, 
          product_id,
          products!product_id (purchase_price)
        ''').inFilter('invoice_id', invoiceIds).eq('is_stock_item', true);

    double revenue = 0.0;
    double cost = 0.0;
    int itemsWithCost = 0;
    int itemsWithoutCost = 0;

    for (final row in (data as List)) {
      final lineTotal = (row['line_total'] as num?)?.toDouble() ?? 0.0;
      final qty = (row['quantity'] as num?)?.toDouble() ?? 0.0;
      final product = row['products'];

      final purchasePrice = product is Map
          ? (product['purchase_price'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      revenue += lineTotal;
      cost += qty * purchasePrice;

      // نعد المنتجات اللي عندها سعر شراء واللي لأ
      if (purchasePrice > 0) {
        itemsWithCost++;
      } else {
        itemsWithoutCost++;
      }
    }

    final profit = revenue - cost;
    final margin = revenue == 0.0 ? 0.0 : (profit / revenue) * 100.0;

    return <String, double>{
      'revenue': revenue,
      'cost': cost,
      'profit': profit,
      'margin': margin,
      'items_with_cost': itemsWithCost.toDouble(),
      'items_without_cost': itemsWithoutCost.toDouble(),
    };
  }

  // =====================================================
  // Helpers
  // =====================================================

  Future<List<String>> _getInvoiceIdsInPeriod(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .select('id')
        .eq('type', 'sale')
        .inFilter('status', ['confirmed', 'paid', 'partial'])
        .gte('invoice_date', _fmt(fromDate))
        .lte('invoice_date', _fmt(toDate));

    return (data as List).map((e) => e['id'] as String).toList();
  }

  static String _fmt(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

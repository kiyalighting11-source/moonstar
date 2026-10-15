// lib/features/reports/providers/reports_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/sales_chart_data.dart';
import '../data/models/sales_summary_model.dart';
import '../data/models/top_product_model.dart';
import '../data/repositories/reports_repository.dart';

// =====================================================
// Repository
// =====================================================
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

// =====================================================
// فلاتر التقارير
// =====================================================
enum ReportPeriod { today, thisWeek, thisMonth, lastMonth, thisYear, custom }

class ReportFilter {
  final ReportPeriod period;
  final DateTime? customFrom;
  final DateTime? customTo;

  const ReportFilter({
    this.period = ReportPeriod.thisMonth,
    this.customFrom,
    this.customTo,
  });

  /// تاريخ البداية الفعلي
  DateTime get fromDate {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.thisWeek:
        final weekday = now.weekday; // 1=Monday .. 7=Sunday
        return DateTime(now.year, now.month, now.day - (weekday - 1));
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.lastMonth:
        return DateTime(now.year, now.month - 1, 1);
      case ReportPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case ReportPeriod.custom:
        return customFrom ?? DateTime(now.year, now.month, 1);
    }
  }

  /// تاريخ النهاية الفعلي
  DateTime get toDate {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriod.thisWeek:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriod.lastMonth:
        return DateTime(now.year, now.month, 0, 23, 59, 59);
      case ReportPeriod.thisYear:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriod.custom:
        return customTo ?? now;
    }
  }

  /// الاسم المعروض بالعربي
  String get labelAr {
    switch (period) {
      case ReportPeriod.today:
        return 'النهاردة';
      case ReportPeriod.thisWeek:
        return 'الأسبوع ده';
      case ReportPeriod.thisMonth:
        return 'الشهر ده';
      case ReportPeriod.lastMonth:
        return 'الشهر اللي فات';
      case ReportPeriod.thisYear:
        return 'السنة دي';
      case ReportPeriod.custom:
        return 'فترة مخصصة';
    }
  }

  ReportFilter copyWith({
    ReportPeriod? period,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    return ReportFilter(
      period: period ?? this.period,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
    );
  }
}

final reportFilterProvider = StateProvider<ReportFilter>((ref) {
  return const ReportFilter();
});

// =====================================================
// ملخص المبيعات للفترة الحالية
// =====================================================
final salesSummaryProvider =
    FutureProvider.autoDispose<SalesSummaryModel>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);

  return await repo.getSalesSummary(
    fromDate: filter.fromDate,
    toDate: filter.toDate,
  );
});

// =====================================================
// ملخص سريع (اليوم / الشهر / السنة)
// =====================================================
final todaySummaryProvider =
    FutureProvider.autoDispose<SalesSummaryModel>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getTodaySummary();
});

final monthSummaryProvider =
    FutureProvider.autoDispose<SalesSummaryModel>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getMonthSummary();
});

final yearSummaryProvider =
    FutureProvider.autoDispose<SalesSummaryModel>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getYearSummary();
});

// =====================================================
// مقارنة الشهر الحالي بالسابق
// =====================================================
final monthComparisonProvider =
    FutureProvider.autoDispose<Map<String, SalesSummaryModel>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getMonthComparison();
});

// =====================================================
// الرسم البياني اليومي
// =====================================================
final dailySalesChartProvider =
    FutureProvider.autoDispose.family<SalesChartData, int>((ref, days) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getDailySalesChart(days: days);
});

// =====================================================
// الرسم البياني الشهري
// =====================================================
final monthlySalesChartProvider =
    FutureProvider.autoDispose.family<SalesChartData, int>((ref, months) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getMonthlySalesChart(months: months);
});

// =====================================================
// الأكثر مبيعاً
// =====================================================
final topProductsProvider =
    FutureProvider.autoDispose<List<TopProductModel>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);

  return await repo.getTopProducts(
    fromDate: filter.fromDate,
    toDate: filter.toDate,
    limit: 10,
  );
});

final topCustomersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);

  return await repo.getTopCustomers(
    fromDate: filter.fromDate,
    toDate: filter.toDate,
    limit: 10,
  );
});

// =====================================================
// الأرباح
// =====================================================
final profitProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);

  return await repo.getProfit(
    fromDate: filter.fromDate,
    toDate: filter.toDate,
  );
});

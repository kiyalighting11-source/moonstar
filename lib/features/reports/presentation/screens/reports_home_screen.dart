// lib/features/reports/presentation/screens/reports_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/sales_summary_model.dart';
import '../../providers/reports_provider.dart';
import '../widgets/sales_summary_card.dart';

class ReportsHomeScreen extends ConsumerWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final todayAsync = ref.watch(todaySummaryProvider);
    final monthAsync = ref.watch(monthSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'التقارير',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(salesSummaryProvider);
              ref.invalidate(todaySummaryProvider);
              ref.invalidate(monthSummaryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesSummaryProvider);
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(monthSummaryProvider);
          await ref.read(salesSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // =====================================================
            // فلتر الفترة
            // =====================================================
            _buildPeriodFilter(context, ref, filter),
            const SizedBox(height: 16),

            // =====================================================
            // إحصائيات سريعة (اليوم / الشهر)
            // =====================================================
            _buildQuickStats(context, todayAsync, monthAsync),

            const SizedBox(height: 24),

            // =====================================================
            // ملخص الفترة المحددة
            // =====================================================
            Text(
              'ملخص الفترة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _buildError(context, e),
              data: (summary) => _buildSummaryGrid(context, summary),
            ),

            const SizedBox(height: 24),

            // =====================================================
            // أزرار التقارير التفصيلية
            // =====================================================
            Text(
              'التقارير التفصيلية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 12),
            _buildReportButtons(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Period Filter
  // =====================================================
  Widget _buildPeriodFilter(
    BuildContext context,
    WidgetRef ref,
    ReportFilter filter,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _periodChip(context, ref, filter, ReportPeriod.today, 'النهاردة'),
          const SizedBox(width: 8),
          _periodChip(context, ref, filter, ReportPeriod.thisWeek, 'الأسبوع'),
          const SizedBox(width: 8),
          _periodChip(context, ref, filter, ReportPeriod.thisMonth, 'الشهر'),
          const SizedBox(width: 8),
          _periodChip(
              context, ref, filter, ReportPeriod.lastMonth, 'الشهر اللي فات'),
          const SizedBox(width: 8),
          _periodChip(context, ref, filter, ReportPeriod.thisYear, 'السنة'),
        ],
      ),
    );
  }

  Widget _periodChip(
    BuildContext context,
    WidgetRef ref,
    ReportFilter current,
    ReportPeriod period,
    String label,
  ) {
    final selected = current.period == period;
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: () {
        ref.read(reportFilterProvider.notifier).state =
            current.copyWith(period: period);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.dividerColor),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textColor(context),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Quick Stats
  // =====================================================
  Widget _buildQuickStats(
    BuildContext context,
    AsyncValue<SalesSummaryModel> todayAsync,
    AsyncValue<SalesSummaryModel> monthAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: todayAsync.when(
            loading: () => _loadingCard(context),
            error: (_, __) => _loadingCard(context),
            data: (s) => SalesSummaryCard(
              title: 'مبيعات النهاردة',
              value: s.totalSales,
              icon: Icons.today,
              color: AppTheme.infoColor,
              valueLabel: '${s.invoicesCount} بيان',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: monthAsync.when(
            loading: () => _loadingCard(context),
            error: (_, __) => _loadingCard(context),
            data: (s) => SalesSummaryCard(
              title: 'مبيعات الشهر',
              value: s.totalSales,
              icon: Icons.calendar_month,
              color: AppTheme.successColor,
              valueLabel: '${s.invoicesCount} بيان',
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingCard(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  // =====================================================
  // Summary Grid
  // =====================================================
  Widget _buildSummaryGrid(BuildContext context, SalesSummaryModel summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SalesSummaryCard(
                title: 'إجمالي المبيعات',
                value: summary.totalSales,
                icon: Icons.trending_up,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SalesSummaryCard(
                title: 'المحصّل',
                value: summary.totalPaid,
                icon: Icons.paid,
                color: AppTheme.successColor,
                valueLabel: '${summary.collectionRate.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SalesSummaryCard(
                title: 'المتبقي',
                value: summary.totalDue,
                icon: Icons.pending_actions,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SalesSummaryCard(
                title: 'الخصومات',
                value: summary.totalDiscount,
                icon: Icons.local_offer,
                color: AppTheme.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _statItem(
                  'عدد البيانات',
                  '${summary.invoicesCount}',
                  Icons.receipt_long,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              Expanded(
                child: _statItem(
                  'متوسط البيان',
                  Helpers.formatCurrency(summary.averageInvoice, decimals: 0),
                  Icons.calculate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Report Buttons
  // =====================================================
  Widget _buildReportButtons(BuildContext context) {
    return Column(
      children: [
        _reportButton(
          context,
          icon: Icons.bar_chart,
          title: 'تقرير المبيعات',
          subtitle: 'يومي / شهري + رسم بياني',
          color: AppTheme.infoColor,
          onTap: () => context.go('/reports/sales'),
        ),
        const SizedBox(height: 8),
        _reportButton(
          context,
          icon: Icons.star,
          title: 'الأكثر مبيعاً',
          subtitle: 'أعلى المنتجات والعملاء',
          color: AppTheme.warningColor,
          onTap: () => context.go('/reports/top-products'),
        ),
        const SizedBox(height: 8),
        _reportButton(
          context,
          icon: Icons.trending_up,
          title: 'الأرباح',
          subtitle: 'الإيرادات والتكاليف والصافي',
          color: AppTheme.successColor,
          onTap: () => context.go('/reports/profit'),
        ),
      ],
    );
  }

  Widget _reportButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondaryColor(context),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Error
  // =====================================================
  Widget _buildError(BuildContext context, Object e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor),
          const SizedBox(height: 8),
          Text(
            'خطأ: $e',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

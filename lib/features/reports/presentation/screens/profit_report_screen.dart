// lib/features/reports/presentation/screens/profit_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/sales_summary_model.dart';
import '../../providers/reports_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class ProfitReportScreen extends ConsumerWidget {
  const ProfitReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);
    final profitAsync = ref.watch(profitProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'تقرير الأرباح',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(profitProvider);
              ref.invalidate(salesSummaryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profitProvider);
          ref.invalidate(salesSummaryProvider);
          await ref.read(profitProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151A23) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    filter.labelAr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            profitAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _errorBox(context, e),
              data: (profit) => _buildProfitCard(context, profit),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) => _buildDetailsCard(context, summary),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Profit Card
  // =====================================================
  Widget _buildProfitCard(BuildContext context, Map<String, double> profit) {
    final netProfit = profit['profit'] ?? 0;
    final margin = profit['margin'] ?? 0;

    final isProfit = netProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [AppTheme.successColor, const Color(0xFF2E7D32)]
              : [AppTheme.errorColor, const Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? AppTheme.successColor : AppTheme.errorColor)
                .withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProfit ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isProfit ? 'صافي الربح' : 'خسارة',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              Helpers.formatCurrency(netProfit),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.percent,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'هامش الربح: ${margin.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Details Card
  // =====================================================
  Widget _buildDetailsCard(BuildContext context, SalesSummaryModel summary) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل الفترة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.trending_up,
            'إجمالي الإيرادات',
            Helpers.formatCurrency(summary.totalSales, decimals: 0),
            AppTheme.primaryColor,
          ),
          _detailRow(
            context,
            Icons.attach_money,
            'المحصّل فعلياً',
            Helpers.formatCurrency(summary.totalPaid, decimals: 0),
            AppTheme.successColor,
          ),
          _detailRow(
            context,
            Icons.pending_actions,
            'المتبقي',
            Helpers.formatCurrency(summary.totalDue, decimals: 0),
            AppTheme.errorColor,
          ),
          _detailRow(
            context,
            Icons.local_offer,
            'إجمالي الخصومات',
            Helpers.formatCurrency(summary.totalDiscount, decimals: 0),
            AppTheme.warningColor,
          ),
          _detailRow(
            context,
            Icons.receipt_long,
            'عدد البيانات',
            '${summary.invoicesCount}',
            AppTheme.infoColor,
          ),
          _detailRow(
            context,
            Icons.calculate,
            'متوسط البيان',
            Helpers.formatCurrency(summary.averageInvoice, decimals: 0),
            AppTheme.textSecondaryColor(context),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Info Card
  // =====================================================
  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.warningColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'الأرباح بتتحسب = الإيرادات - تكلفة الشراء.\n'
              'عشان تظهر الأرباح بدقة، ضيف سعر الشراء لكل منتج.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Error
  // =====================================================
  Widget _errorBox(BuildContext context, Object e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'خطأ: $e',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textColor(context),
        ),
      ),
    );
  }
}

// lib/features/reports/presentation/screens/sales_report_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/sales_chart_data.dart';
import '../../data/models/sales_summary_model.dart';
import '../../providers/reports_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  int _days = 30;
  int _months = 12;
  bool _isDaily = true;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reportFilterProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final chartAsync = _isDaily
        ? ref.watch(dailySalesChartProvider(_days))
        : ref.watch(monthlySalesChartProvider(_months));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'تقرير المبيعات',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(salesSummaryProvider);
              ref.invalidate(dailySalesChartProvider(_days));
              ref.invalidate(monthlySalesChartProvider(_months));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesSummaryProvider);
          if (_isDaily) {
            ref.invalidate(dailySalesChartProvider(_days));
          } else {
            ref.invalidate(monthlySalesChartProvider(_months));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart,
                  color: AppTheme.infoColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  filter.labelAr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _errorBox(context, e),
              data: (s) => _buildSummaryBox(context, s),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('يومي'),
                  icon: Icon(Icons.calendar_today, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('شهري'),
                  icon: Icon(Icons.calendar_month, size: 16),
                ),
              ],
              selected: {_isDaily},
              onSelectionChanged: (s) => setState(() => _isDaily = s.first),
            ),
            const SizedBox(height: 12),
            _buildRangeChips(context),
            const SizedBox(height: 16),
            chartAsync.when(
              loading: () => const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _errorBox(context, e),
              data: (data) => _buildChartCard(context, data),
            ),
            const SizedBox(height: 16),
            chartAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => _buildChartStats(context, data),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Range Chips
  // =====================================================
  Widget _buildRangeChips(BuildContext context) {
    if (_isDaily) {
      return SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _rangeChip(context, 7, '7 أيام'),
            const SizedBox(width: 8),
            _rangeChip(context, 14, '14 يوم'),
            const SizedBox(width: 8),
            _rangeChip(context, 30, '30 يوم'),
            const SizedBox(width: 8),
            _rangeChip(context, 60, '60 يوم'),
            const SizedBox(width: 8),
            _rangeChip(context, 90, '90 يوم'),
          ],
        ),
      );
    } else {
      return SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _monthChip(context, 3, '3 شهور'),
            const SizedBox(width: 8),
            _monthChip(context, 6, '6 شهور'),
            const SizedBox(width: 8),
            _monthChip(context, 12, 'سنة'),
            const SizedBox(width: 8),
            _monthChip(context, 24, 'سنتين'),
          ],
        ),
      );
    }
  }

  Widget _rangeChip(BuildContext context, int days, String label) {
    final selected = _days == days;
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: () => setState(() => _days = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.infoColor
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.infoColor
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
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthChip(BuildContext context, int months, String label) {
    final selected = _months == months;
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: () => setState(() => _months = months),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Summary Box
  // =====================================================
  Widget _buildSummaryBox(BuildContext context, SalesSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.infoColor, AppTheme.primaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(
                'الإجمالي',
                Helpers.formatCurrency(summary.totalSales, decimals: 0),
              ),
              _summaryItem('عدد البيانات', '${summary.invoicesCount}'),
            ],
          ),
          const Divider(color: Colors.white30, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(
                'المحصّل',
                Helpers.formatCurrency(summary.totalPaid, decimals: 0),
              ),
              _summaryItem(
                'المتبقي',
                Helpers.formatCurrency(summary.totalDue, decimals: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Chart
  // =====================================================
  Widget _buildChartCard(BuildContext context, SalesChartData data) {
    final isDark = AppTheme.isDark(context);

    if (data.points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 60,
              color: AppTheme.textSecondaryColor(context),
            ),
            const SizedBox(height: 12),
            Text(
              'مفيش بيانات في الفترة دي',
              style: TextStyle(color: AppTheme.textSecondaryColor(context)),
            ),
          ],
        ),
      );
    }

    final maxY = data.max == 0 ? 100.0 : data.max * 1.2;

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
          Row(
            children: [
              const Icon(
                Icons.show_chart,
                size: 18,
                color: AppTheme.infoColor,
              ),
              const SizedBox(width: 6),
              Text(
                _isDaily ? 'المبيعات اليومية' : 'المبيعات الشهرية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _isDaily
                ? _buildLineChart(context, data, maxY)
                : _buildBarChart(context, data, maxY),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    BuildContext context,
    SalesChartData data,
    double maxY,
  ) {
    final isDark = AppTheme.isDark(context);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _compactNumber(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (data.points.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.points.length) {
                  return const SizedBox.shrink();
                }
                final point = data.points[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isDaily
                        ? DateFormat('dd/MM').format(point.date)
                        : _monthShort(point.date.month),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.points.length,
              (i) => FlSpot(
                i.toDouble(),
                data.points[i].value,
              ),
            ),
            isCurved: true,
            color: AppTheme.infoColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.infoColor.withValues(alpha: 0.3),
                  AppTheme.infoColor.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    SalesChartData data,
    double maxY,
  ) {
    final isDark = AppTheme.isDark(context);

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _compactNumber(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.points.length) {
                  return const SizedBox.shrink();
                }
                final point = data.points[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _monthShort(point.date.month),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          data.points.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data.points[i].value,
                color: AppTheme.primaryColor,
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Chart Stats
  // =====================================================
  Widget _buildChartStats(BuildContext context, SalesChartData data) {
    if (data.points.isEmpty) return const SizedBox.shrink();
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          _statRow(
            context,
            Icons.trending_up,
            'الإجمالي',
            Helpers.formatCurrency(data.total, decimals: 0),
            AppTheme.primaryColor,
          ),
          _statRow(
            context,
            Icons.arrow_upward,
            'أعلى يوم',
            Helpers.formatCurrency(data.max, decimals: 0),
            AppTheme.successColor,
          ),
          _statRow(
            context,
            Icons.arrow_downward,
            'أقل يوم',
            Helpers.formatCurrency(data.min, decimals: 0),
            AppTheme.warningColor,
          ),
          _statRow(
            context,
            Icons.show_chart,
            'المتوسط',
            Helpers.formatCurrency(data.average, decimals: 0),
            AppTheme.infoColor,
          ),
        ],
      ),
    );
  }

  Widget _statRow(
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Helpers
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

  String _compactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _monthShort(int month) {
    const months = [
      'ينا',
      'فبر',
      'مار',
      'أبر',
      'ماي',
      'يون',
      'يول',
      'أغس',
      'سبت',
      'أكت',
      'نوف',
      'ديس',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}

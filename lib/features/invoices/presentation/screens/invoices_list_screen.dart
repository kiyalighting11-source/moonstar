// lib/features/invoices/presentation/screens/invoices_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/invoices_provider.dart';
import '../widgets/invoice_card.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleCode = ref.watch(currentRoleProvider);
    final canCreate = roleCode == AppConstants.roleAdmin ||
        roleCode == AppConstants.roleManager ||
        roleCode == AppConstants.roleCashier;

    final invoicesAsync = ref.watch(filteredInvoicesProvider);
    final filter = ref.watch(invoicesFilterProvider);
    final statsAsync = ref.watch(invoicesStatsProvider);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'البيانات',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(invoicesListProvider);
              ref.invalidate(invoicesStatsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/invoices/add'),
              icon: const Icon(Icons.add),
              label: const Text('بيان جديد'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // ==================== إحصائيات ====================
          statsAsync.when(
            loading: () => const SizedBox(height: 0),
            error: (_, __) => const SizedBox(height: 0),
            data: (stats) => _buildStatsBar(context, stats, isDark),
          ),

          // ==================== بحث ====================
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  ref.read(invoicesFilterProvider.notifier).state =
                      filter.copyWith(search: v);
                },
                decoration: InputDecoration(
                  hintText: 'ابحث برقم البيان أو ملاحظة...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(invoicesFilterProvider.notifier).state =
                                filter.copyWith(clearSearch: true);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // ==================== فلتر الحالة ====================
          _buildStatusFilters(context, filter, isDark),

          const SizedBox(height: 8),

          // ==================== القائمة ====================
          Expanded(
            child: invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildError(context, e),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return _buildEmpty(context, canCreate);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(filteredInvoicesProvider);
                    ref.invalidate(invoicesStatsProvider);
                    await ref.read(filteredInvoicesProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final invoice = invoices[i];
                      return InvoiceCard(
                        invoice: invoice,
                        onTap: () => context.go('/invoices/${invoice.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(
    BuildContext context,
    Map<String, dynamic> stats,
    bool isDark,
  ) {
    final allCount = stats['all_count'] as int? ?? 0;
    final monthCount = stats['month_count'] as int? ?? 0;
    final totalDue = (stats['total_due'] as num?)?.toDouble() ?? 0;
    final monthSales = (stats['month_sales'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statBox(
                  context,
                  'فواتير الشهر',
                  '$monthCount',
                  Icons.receipt_long,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  context,
                  'مبيعات الشهر',
                  Helpers.formatCurrency(monthSales, decimals: 0),
                  Icons.trending_up,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  context,
                  'إجمالي الفواتير',
                  '$allCount',
                  Icons.description,
                  AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  context,
                  'المستحقات',
                  Helpers.formatCurrency(totalDue, decimals: 0),
                  Icons.pending_actions,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(
    BuildContext context,
    InvoicesFilter filter,
    bool isDark,
  ) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip(context, 'الكل', null, filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'مسودة', 'draft', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'عروض سعر', 'quote', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'مؤكدة', 'confirmed', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'جزئية', 'partial', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'مدفوعة', 'paid', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'ملغية', 'cancelled', filter, isDark),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    String? status,
    InvoicesFilter filter,
    bool isDark,
  ) {
    final selected =
        status == null ? filter.status == null : filter.status == status;

    return GestureDetector(
      onTap: () {
        if (status == null) {
          ref.read(invoicesFilterProvider.notifier).state =
              filter.copyWith(clearStatus: true);
        } else {
          ref.read(invoicesFilterProvider.notifier).state =
              filter.copyWith(status: status);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textColor(context),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool canCreate) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مفيش بيانات لسه',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإنشاء أول بيان',
            style: TextStyle(color: AppTheme.textSecondaryColor(context)),
          ),
          if (canCreate) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/invoices/add'),
              icon: const Icon(Icons.add),
              label: const Text('بيان جديد'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(filteredInvoicesProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

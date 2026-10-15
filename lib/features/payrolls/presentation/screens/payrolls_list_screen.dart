// lib/features/payrolls/presentation/screens/payrolls_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/repositories/payrolls_repository.dart';
import '../../providers/payrolls_provider.dart';
import '../widgets/payroll_card.dart';

class PayrollsListScreen extends ConsumerStatefulWidget {
  const PayrollsListScreen({super.key});

  @override
  ConsumerState<PayrollsListScreen> createState() => _PayrollsListScreenState();
}

class _PayrollsListScreenState extends ConsumerState<PayrollsListScreen> {
  String? _selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final roleCode = ref.watch(currentRoleProvider);
    final isAdmin = roleCode == AppConstants.roleAdmin;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const DashboardAppBar(
          title: 'الرواتب',
          actions: [
            ThemeToggleButton(),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: AppTheme.textSecondaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'هذا القسم للأدمن فقط',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final payrollsAsync = ref.watch(allPayrollsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'الرواتب',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allPayrollsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGenerateOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('كشف جديد'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildPeriodFilter(context, payrollsAsync),
          Expanded(
            child: payrollsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildError(context, e),
              data: (list) {
                final filtered = _selectedPeriod == null
                    ? list
                    : list
                        .where((p) => p.periodLabel == _selectedPeriod)
                        .toList();

                if (filtered.isEmpty) {
                  return _buildEmpty(context);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allPayrollsProvider);
                    await ref.read(allPayrollsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return PayrollCard(
                        payroll: p,
                        onTap: () => context.go('/payrolls/${p.id}'),
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

  Widget _buildPeriodFilter(
    BuildContext context,
    AsyncValue<List<dynamic>> payrollsAsync,
  ) {
    final list = payrollsAsync.value ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    final isDark = AppTheme.isDark(context);
    final periods = list.map((p) => p.periodLabel as String).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _filterChip(context, 'الكل', null, isDark),
            ...periods.map((p) => _filterChip(context, p, p, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    String? value,
    bool isDark,
  ) {
    final selected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.transparent),
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
                fontSize: 13,
                color: selected ? Colors.white : AppTheme.textColor(context),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGenerateOptions(BuildContext context) {
    final (start, end) = PayrollsRepository.currentPeriod();
    final label = PayrollsRepository.periodLabel(start, end);
    final isDark = AppTheme.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'كشف جديد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: AppTheme.primaryColor,
              ),
              title: Text(
                'الفترة الحالية: $label',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              subtitle: Text(
                '${Helpers.formatDate(start)} → ${Helpers.formatDate(end)}',
                style: TextStyle(color: AppTheme.textSecondaryColor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/payrolls/generate');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
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
              Icons.payments_outlined,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مفيش كشوف رواتب لسه',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإنشاء كشف جديد',
            style: TextStyle(color: AppTheme.textSecondaryColor(context)),
          ),
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
              onPressed: () => ref.invalidate(allPayrollsProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

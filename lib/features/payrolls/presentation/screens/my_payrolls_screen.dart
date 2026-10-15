// lib/features/payrolls/presentation/screens/my_payrolls_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../advances/data/models/advance_model.dart';
import '../../../advances/providers/advances_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../providers/payrolls_provider.dart';
import '../widgets/payroll_card.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class MyPayrollsScreen extends ConsumerStatefulWidget {
  const MyPayrollsScreen({super.key});

  @override
  ConsumerState<MyPayrollsScreen> createState() => _MyPayrollsScreenState();
}

class _MyPayrollsScreenState extends ConsumerState<MyPayrollsScreen> {
  EmployeeModel? _employee;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _error = 'يجب تسجيل الدخول';
        return;
      }

      final emp = await ref
          .read(employeesRepositoryProvider)
          .getEmployeeByProfileId(user.id);

      if (emp == null) {
        _error = 'لا يوجد ملف موظف مرتبط بحسابك';
        return;
      }

      _employee = emp;
    } catch (e) {
      _error = 'فشل التحميل: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: DashboardAppBar(
        title: 'رواتبي',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadEmployee,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmployee,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final payrollsAsync = ref.watch(employeePayrollsProvider(_employee!.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(employeePayrollsProvider(_employee!.id));
        ref.invalidate(currentMonthAdvancesProvider(_employee!.id));
        await ref.read(employeePayrollsProvider(_employee!.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // =====================================================
          // ⭐ قسم السلف خلال الشهر الجاري
          // =====================================================
          _buildCurrentMonthAdvancesSection(),

          const SizedBox(height: 24),

          // =====================================================
          // قسم كشوف الرواتب
          // =====================================================
          const Text(
            'كشوف رواتبي',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          payrollsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('خطأ: $e', textAlign: TextAlign.center),
            ),
            data: (list) {
              if (list.isEmpty) {
                return _buildEmptyPayrolls();
              }
              return Column(
                children: list
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PayrollCard(
                          payroll: p,
                          onTap: () => context.go('/payrolls/${p.id}'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ⭐ قسم السلف خلال الشهر الجاري
  // =====================================================
  Widget _buildCurrentMonthAdvancesSection() {
    final advancesAsync =
        ref.watch(currentMonthAdvancesProvider(_employee!.id));

    final now = DateTime.now();
    final monthName = _monthNameAr(now.month);
    final year = now.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.money_off,
              color: AppTheme.warningColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'سلفي خلال $monthName $year',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        advancesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'خطأ: $e',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ),
          data: (advances) {
            if (advances.isEmpty) {
              return _buildEmptyAdvances();
            }
            return _buildAdvancesList(advances);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyAdvances() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppTheme.successColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'مفيش سلف أخدتها الشهر ده 🎉',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancesList(List<AdvanceModel> advances) {
    // الإجمالي
    double total = 0;
    double remaining = 0;
    for (final a in advances) {
      total += a.amount;
      remaining += a.remainingAmount;
    }

    return Column(
      children: [
        // ===== إجمالي الشهر =====
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warningColor.withValues(alpha: 0.15),
                AppTheme.warningColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.warningColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: AppTheme.warningColor,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${advances.length} سلفة',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Helpers.formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
                    if (remaining > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'متبقي: ${Helpers.formatCurrency(remaining)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ===== كل سلفة =====
        ...advances.map((a) => _advanceTile(a)),
      ],
    );
  }

  Widget _advanceTile(AdvanceModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (a.isFullyPaid
                      ? AppTheme.successColor
                      : AppTheme.warningColor)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              a.isFullyPaid ? Icons.check_circle : Icons.pending_actions,
              color:
                  a.isFullyPaid ? AppTheme.successColor : AppTheme.warningColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // التفاصيل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Helpers.formatCurrency(a.amount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 10,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Helpers.formatDate(a.advanceDate),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (a.isInstallment) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• قسط ${a.paidMonths}/${a.installmentMonths}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ],
                  ],
                ),
                if (a.reason != null && a.reason!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    a.reason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // الحالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (a.isFullyPaid
                      ? AppTheme.successColor
                      : AppTheme.warningColor)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              a.isFullyPaid ? 'مسددة' : 'مستحقة',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: a.isFullyPaid
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPayrolls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'مفيش كشوف رواتب لسه',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'الكشوف بيعملها الأدمن',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Helper: اسم الشهر بالعربي
  // =====================================================
  static String _monthNameAr(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}

// lib/features/advances/presentation/screens/my_advances_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../data/models/advance_model.dart';
import '../../providers/advances_provider.dart';
import '../widgets/advance_card.dart';

class MyAdvancesScreen extends ConsumerStatefulWidget {
  const MyAdvancesScreen({super.key});

  @override
  ConsumerState<MyAdvancesScreen> createState() => _MyAdvancesScreenState();
}

class _MyAdvancesScreenState extends ConsumerState<MyAdvancesScreen> {
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

      final all = await ref.read(employeesRepositoryProvider).getAllEmployees();
      _employee = all.where((e) => e.profileId == user.id).firstOrNull;

      if (_employee == null) {
        _error = 'لا يوجد ملف موظف مرتبط بحسابك';
      }
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
        title: 'سلفي',
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
    final async = ref.watch(employeeAdvancesProvider(_employee!.id));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (list) {
        if (list.isEmpty) {
          return _buildEmpty();
        }

        final stats = _calculateStats(list);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(employeeAdvancesProvider(_employee!.id));
            await ref.read(employeeAdvancesProvider(_employee!.id).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // إحصائيات
              _buildStats(stats),
              const SizedBox(height: 16),

              // تحذير لو فيه سلف مستحقة
              if ((stats['remaining'] ?? 0) > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'إجمالي السلف المستحقة: '
                          '${Helpers.formatCurrency(stats['remaining'] ?? 0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'كل السلف',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...list.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AdvanceCard(advance: a),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats(Map<String, double> stats) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'إجمالي',
            Helpers.formatCurrency(stats['total'] ?? 0, decimals: 0),
            Icons.account_balance_wallet,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'متبقي',
            Helpers.formatCurrency(stats['remaining'] ?? 0, decimals: 0),
            Icons.pending_actions,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'مسدد',
            Helpers.formatCurrency(stats['paid'] ?? 0, decimals: 0),
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
              Icons.money_off,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'مفيش سلف لسه',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'السلف بتتسجل من الإدارة',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateStats(List<AdvanceModel> list) {
    double total = 0;
    double remaining = 0;
    double paid = 0;

    for (final a in list) {
      total += a.amount;
      remaining += a.remainingAmount;
      paid += a.paidAmount;
    }

    return {'total': total, 'remaining': remaining, 'paid': paid};
  }
}

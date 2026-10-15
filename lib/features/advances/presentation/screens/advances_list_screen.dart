// lib/features/advances/presentation/screens/advances_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/advance_model.dart';
import '../../providers/advances_provider.dart';
import '../widgets/advance_card.dart';

class AdvancesListScreen extends ConsumerWidget {
  const AdvancesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleCode = ref.watch(currentRoleProvider);
    final isAdminOrManager = roleCode == AppConstants.roleAdmin ||
        roleCode == AppConstants.roleManager;

    // لو الموظف → نوجهه لصفحة "سلفي"
    if (!isAdminOrManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppConstants.routeMyAdvances);
      });
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final advancesAsync = ref.watch(allAdvancesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'السلف',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allAdvancesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppConstants.routeAddAdvance),
        icon: const Icon(Icons.add),
        label: const Text('سلفة جديدة'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: advancesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, ref, e),
        data: (list) {
          if (list.isEmpty) {
            return _buildEmpty(context);
          }

          final stats = _calculateStats(list);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allAdvancesProvider);
              await ref.read(allAdvancesProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildStats(context, stats),
                const SizedBox(height: 16),
                Text(
                  'كل السلف',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                ...list.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AdvanceCard(
                      advance: a,
                      onTap: () => _showActions(context, ref, a),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats(BuildContext context, Map<String, double> stats) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            'إجمالي',
            Helpers.formatCurrency(stats['total'] ?? 0, decimals: 0),
            Icons.account_balance_wallet,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            'متبقي',
            Helpers.formatCurrency(stats['remaining'] ?? 0, decimals: 0),
            Icons.pending_actions,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            'مسدد',
            Helpers.formatCurrency(stats['paid'] ?? 0, decimals: 0),
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
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
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
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
              Icons.money_off,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مفيش سلف لسه',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go(AppConstants.routeAddAdvance),
            icon: const Icon(Icons.add),
            label: const Text('إضافة سلفة'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object e) {
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
              onPressed: () => ref.invalidate(allAdvancesProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
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

  void _showActions(BuildContext context, WidgetRef ref, AdvanceModel a) {
    final isDark = AppTheme.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              a.employeeName ?? 'موظف',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Helpers.formatCurrency(a.amount),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.infoColor),
              title: Text(
                'تعديل',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/advances/edit/${a.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: Text(
                'حذف',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await Helpers.confirmDialog(
                  context,
                  title: 'حذف السلفة',
                  message: 'هل أنت متأكد من حذف السلفة؟',
                  confirmText: 'حذف',
                  confirmColor: AppTheme.errorColor,
                );
                if (!confirm) return;

                final success = await ref
                    .read(advancesControllerProvider.notifier)
                    .deleteAdvance(a.id, a.employeeId);

                if (!context.mounted) return;
                if (success) {
                  Helpers.showSuccess(context, 'تم الحذف');
                } else {
                  Helpers.showError(context, 'فشل الحذف');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

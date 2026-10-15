// lib/features/payrolls/presentation/screens/payroll_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../data/models/payroll_model.dart';
import '../../providers/payrolls_provider.dart';

class PayrollDetailsScreen extends ConsumerWidget {
  final String payrollId;

  const PayrollDetailsScreen({
    super.key,
    required this.payrollId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⭐ حماية: لو الـ id مش UUID، اعرض "مش موجود"
    if (!_isValidUuid(payrollId)) {
      return _buildInvalidId(context);
    }

    final async = ref.watch(payrollByIdProvider(payrollId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'تفاصيل الكشف',
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ),
        data: (payroll) {
          if (payroll == null) {
            return Center(
              child: Text(
                'الكشف غير موجود',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            );
          }
          return _buildContent(context, ref, payroll);
        },
      ),
    );
  }

  Widget _buildInvalidId(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'تفاصيل الكشف',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: AppTheme.textSecondaryColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                'كشف الراتب غير موجود',
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PayrollModel p,
  ) {
    final isDark = AppTheme.isDark(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(payrollByIdProvider(payrollId));
        await ref.read(payrollByIdProvider(payrollId).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =====================================================
          // Header
          // =====================================================
          _buildHeader(context, p, isDark),

          const SizedBox(height: 16),

          // =====================================================
          // الموظف
          // =====================================================
          _section(context, isDark, 'الموظف', [
            _row(context, Icons.person, 'الاسم', p.employeeName ?? '-'),
            _row(context, Icons.badge, 'الكود', p.employeeCode ?? '-'),
            if (p.employeeJobTitle != null)
              _row(
                context,
                Icons.work_outline,
                'الوظيفة',
                p.employeeJobTitle!,
              ),
          ]),

          const SizedBox(height: 12),

          // =====================================================
          // الفترة
          // =====================================================
          _section(context, isDark, 'الفترة', [
            _row(
              context,
              Icons.calendar_today,
              'من',
              Helpers.formatDate(p.periodStart),
            ),
            _row(
              context,
              Icons.calendar_today,
              'إلى',
              Helpers.formatDate(p.periodEnd),
            ),
            _row(context, Icons.event, 'المسمى', p.periodLabel),
          ]),

          const SizedBox(height: 12),

          // =====================================================
          // الملخص المالي
          // =====================================================
          _section(context, isDark, 'الملخص المالي', [
            _row(
              context,
              Icons.attach_money,
              'الراتب الأساسي',
              Helpers.formatCurrency(p.basicSalary),
            ),
            if (p.bonus > 0)
              _row(
                context,
                Icons.card_giftcard,
                'مكافأة',
                '+ ${Helpers.formatCurrency(p.bonus)}',
                color: AppTheme.successColor,
              ),
            _row(
              context,
              Icons.trending_down,
              'إجمالي الخصومات',
              '- ${Helpers.formatCurrency(p.totalDeductions)}',
              color: AppTheme.errorColor,
            ),
            Divider(
              height: 20,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.dividerColor,
            ),
            _row(
              context,
              Icons.payments,
              'الصافي',
              Helpers.formatCurrency(p.netSalary),
              color: AppTheme.successColor,
              bold: true,
            ),
          ]),

          const SizedBox(height: 12),

          // =====================================================
          // الحضور
          // =====================================================
          _section(context, isDark, 'الحضور', [
            _row(
              context,
              Icons.check_circle,
              'أيام الحضور',
              '${p.presentDays} يوم',
              color: AppTheme.successColor,
            ),
            if (p.absentDays > 0)
              _row(
                context,
                Icons.cancel,
                'أيام الغياب',
                '${p.absentDays} يوم',
                color: AppTheme.errorColor,
              ),
            if (p.totalLateMinutes > 0)
              _row(
                context,
                Icons.access_time,
                'إجمالي التأخير',
                Helpers.formatMinutes(p.totalLateMinutes),
                color: AppTheme.warningColor,
              ),
          ]),

          // =====================================================
          // تفاصيل السلف
          // =====================================================
          if (p.advancesDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            _section(
              context,
              isDark,
              'السلف المخصومة',
              p.advancesDetails.map((a) {
                final date = DateTime.tryParse(a['date'] ?? '');
                final deducted = (a['deducted'] as num?)?.toDouble() ?? 0;
                final reason = a['reason'] as String?;
                final months = a['installment_months'] as int? ?? 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.money_off,
                              size: 16,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'سلفة ${Helpers.formatDate(date)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                            ),
                            Text(
                              Helpers.formatCurrency(deducted),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                        if (reason != null && reason.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'السبب: $reason',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ],
                        if (months > 1) ...[
                          const SizedBox(height: 4),
                          Text(
                            'مقسمة على $months شهور',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // =====================================================
          // الحالة
          // =====================================================
          const SizedBox(height: 12),
          _section(context, isDark, 'الحالة', [
            _row(
              context,
              p.isPaid ? Icons.check_circle : Icons.pending,
              'حالة القبض',
              p.statusLabelAr,
              color: p.isPaid ? AppTheme.successColor : AppTheme.warningColor,
            ),
            if (p.paidAt != null)
              _row(
                context,
                Icons.access_time,
                'تاريخ القبض',
                Helpers.formatDateTime(p.paidAt),
              ),
            if (p.paidByName != null)
              _row(context, Icons.person, 'استلم بواسطة', p.paidByName!),
          ]),

          const SizedBox(height: 24),

          // =====================================================
          // زرار تأكيد القبض
          // =====================================================
          if (!p.isPaid)
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _markAsPaid(context, ref, p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'تأكيد القبض',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(
    BuildContext context,
    WidgetRef ref,
    PayrollModel p,
  ) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'تأكيد القبض',
      message: 'هل تريد تأكيد القبض؟\n\nسيتم خصم السلف المستحقة تلقائياً.',
      confirmText: 'تأكيد القبض',
    );

    if (!confirm) return;

    // ⭐ DEBUG
    debugPrint('═══════════════════════════════════════');
    debugPrint('💰 _markAsPaid');
    debugPrint('  payrollId: ${p.id}');
    debugPrint('  employeeId: ${p.employeeId}');
    debugPrint('  netSalary: ${p.netSalary}');
    debugPrint('  advancesDeduction: ${p.advancesDeduction}');
    debugPrint('  advancesDetails count: ${p.advancesDetails.length}');
    for (final a in p.advancesDetails) {
      debugPrint(
        '  - advance_id=${a['advance_id']}, deducted=${a['deducted']}',
      );
    }
    debugPrint('═══════════════════════════════════════');

    final result = await ref
        .read(payrollsControllerProvider.notifier)
        .markAsPaid(p.id, p.employeeId);

    if (!context.mounted) return;

    if (result != null) {
      Helpers.showSuccess(context, 'تم تأكيد القبض ✅');
    } else {
      final error = ref.read(payrollsControllerProvider).error;
      Helpers.showError(context, 'فشل التأكيد: $error');
    }
  }

  // =====================================================
  // Widgets
  // =====================================================

  Widget _buildHeader(
    BuildContext context,
    PayrollModel p,
    bool isDark,
  ) {
    final color = p.isPaid ? AppTheme.successColor : AppTheme.warningColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            p.isPaid ? Icons.verified : Icons.pending_actions,
            color: color,
            size: 50,
          ),
          const SizedBox(height: 10),
          Text(
            p.statusLabelAr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.payrollNumber,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'صافي: ${Helpers.formatCurrency(p.netSalary)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    bool isDark,
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondaryColor(context),
          ),
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
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // UUID validation
  // =====================================================
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool _isValidUuid(String s) => _uuidRegex.hasMatch(s);
}

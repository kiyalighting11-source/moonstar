// lib/features/payrolls/presentation/widgets/payroll_card.dart

import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/utils/helpers.dart';
import '../../data/models/payroll_model.dart';

class PayrollCard extends StatelessWidget {
  final PayrollModel payroll;
  final VoidCallback? onTap;

  const PayrollCard({
    super.key,
    required this.payroll,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final statusColor = _statusColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== الصف الأول =====
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Text(
                    Helpers.initials(payroll.employeeName ?? '?'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (payroll.employeeName != null)
                        Text(
                          payroll.employeeName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 11,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payroll.periodLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                          if (payroll.employeeCode != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              payroll.employeeCode!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge الحالة
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.dividerColor,
            ),
            const SizedBox(height: 8),

            // ===== الملخص المالي =====
            Row(
              children: [
                Expanded(
                  child: _amountItem(
                    context,
                    'الأساسي',
                    Helpers.formatCurrency(payroll.basicSalary, decimals: 0),
                    AppTheme.textSecondaryColor(context),
                  ),
                ),
                Expanded(
                  child: _amountItem(
                    context,
                    'الخصومات',
                    '-${Helpers.formatCurrency(payroll.totalDeductions, decimals: 0)}',
                    AppTheme.errorColor,
                  ),
                ),
                Expanded(
                  child: _amountItem(
                    context,
                    'الصافي',
                    Helpers.formatCurrency(payroll.netSalary, decimals: 0),
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),

            // ===== الحضور =====
            if (payroll.presentDays > 0 || payroll.absentDays > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _miniChip(
                    'حضور ${payroll.presentDays} يوم',
                    AppTheme.successColor,
                  ),
                  if (payroll.absentDays > 0)
                    _miniChip(
                      'غياب ${payroll.absentDays}',
                      AppTheme.errorColor,
                    ),
                  if (payroll.totalLateMinutes > 0)
                    _miniChip(
                      'تأخير ${(payroll.totalLateMinutes / 60).toStringAsFixed(1)} س',
                      AppTheme.warningColor,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            payroll.isPaid ? Icons.check_circle : Icons.pending_actions,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            payroll.statusLabelAr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _amountItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color get _statusColor =>
      payroll.isPaid ? AppTheme.successColor : AppTheme.warningColor;
}

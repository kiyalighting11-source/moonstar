// lib/features/advances/presentation/widgets/advance_card.dart

import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/utils/helpers.dart';
import '../../data/models/advance_model.dart';

class AdvanceCard extends StatelessWidget {
  final AdvanceModel advance;
  final VoidCallback? onTap;

  const AdvanceCard({
    super.key,
    required this.advance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final statusColor = _statusColor;
    final statusIcon = _statusIcon;

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
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (advance.employeeName != null) ...[
                        Text(
                          advance.employeeName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.formatDate(advance.advanceDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                          if (advance.employeeCode != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              advance.employeeCode!,
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

            // ===== المبالغ =====
            Row(
              children: [
                Expanded(
                  child: _amountItem(
                    context,
                    'المبلغ',
                    Helpers.formatCurrency(advance.amount, decimals: 0),
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _amountItem(
                    context,
                    'متبقي',
                    Helpers.formatCurrency(advance.remainingAmount,
                        decimals: 0),
                    advance.isFullyPaid
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
                if (advance.isInstallment)
                  Expanded(
                    child: _amountItem(
                      context,
                      'القسط',
                      Helpers.formatCurrency(
                        advance.installmentAmount,
                        decimals: 0,
                      ),
                      AppTheme.infoColor,
                    ),
                  ),
              ],
            ),

            // ===== Progress Bar للتقسيط =====
            if (advance.isInstallment && !advance.isFullyPaid) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: advance.progressPercent / 100,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(
                    AppTheme.infoColor,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'قسط ${advance.paidMonths}/${advance.installmentMonths}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  Text(
                    '${advance.progressPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.infoColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // ===== السبب =====
            if (advance.reason != null && advance.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  advance.reason!,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
      child: Text(
        advance.statusLabelAr,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
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

  Color get _statusColor {
    if (advance.isFullyPaid) return AppTheme.successColor;
    if (advance.isInstallment) return AppTheme.infoColor;
    return AppTheme.warningColor;
  }

  IconData get _statusIcon {
    if (advance.isFullyPaid) return Icons.check_circle;
    if (advance.isInstallment) return Icons.payments;
    return Icons.pending_actions;
  }
}

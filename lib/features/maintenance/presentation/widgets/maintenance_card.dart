// lib/features/maintenance/presentation/widgets/maintenance_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/maintenance_model.dart';
import 'maintenance_status_badge.dart';

class MaintenanceCard extends StatelessWidget {
  final MaintenanceModel ticket;
  final VoidCallback? onTap;

  const MaintenanceCard({
    super.key,
    required this.ticket,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final statusColor = _statusColor(ticket.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // الصف الأول: رقم التذكرة + الحالة + الأولوية
            // =====================================================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(ticket.status),
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ticket.ticketNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MaintenancePriorityBadge(
                            priority: ticket.priority,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Helpers.formatDate(ticket.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                MaintenanceStatusBadge(status: ticket.status),
              ],
            ),

            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 12),

            // =====================================================
            // بيانات العميل
            // =====================================================
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    Helpers.initials(ticket.customerName ?? '?'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.customerName ?? 'بدون عميل',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      if (ticket.customerPhone != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 10,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ticket.customerPhone!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryColor(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // =====================================================
            // الأجهزة (عدد + أسماء)
            // =====================================================
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : AppTheme.lightBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.build_circle,
                      size: 14,
                      color: AppTheme.infoColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ticket.devicesCount} جهاز',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        if (ticket.devices.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            ticket.devices
                                .take(2)
                                .map((d) => d.displayName)
                                .join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (ticket.hasParts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${ticket.partsCount} قطعة',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // =====================================================
            // الملخص المالي
            // =====================================================
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _amountItem(
                    context,
                    'الإجمالي',
                    ticket.totalCost,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _amountItem(
                    context,
                    'المدفوع',
                    ticket.paidAmount,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _amountItem(
                    context,
                    'المتبقي',
                    ticket.dueAmount,
                    ticket.dueAmount > 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                  ),
                ),
              ],
            ),

            // =====================================================
            // الفني
            // =====================================================
            if (ticket.hasTechnician) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_pin,
                    size: 14,
                    color: AppTheme.infoColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'الفني: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  Text(
                    ticket.technicianName ?? 'غير محدد',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 12,
                      color: AppTheme.warningColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'لم يتم تعيين فني',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountItem(
    BuildContext context,
    String label,
    double value,
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
            Helpers.formatCurrency(value, decimals: 0),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return AppTheme.infoColor;
      case 'diagnosing':
        return const Color(0xFF7E57C2);
      case 'repairing':
        return const Color(0xFFFB8C00);
      case 'waiting_parts':
        return AppTheme.errorColor;
      case 'ready':
        return const Color(0xFF00ACC1);
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'new':
        return Icons.fiber_new;
      case 'diagnosing':
        return Icons.search;
      case 'repairing':
        return Icons.build;
      case 'waiting_parts':
        return Icons.hourglass_empty;
      case 'ready':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

// lib/features/invoices/presentation/widgets/invoice_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/invoice_model.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(invoice.status);
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== الصف الأول ====================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(invoice.status),
                    color: statusColor,
                    size: 20,
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
                              invoice.customerName ?? 'بدون عميل',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                          ),
                          if (invoice.isSaleReturn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.errorColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'مرتجع',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (invoice.isQuote) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.infoColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'عرض سعر',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.infoColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.receipt,
                            size: 11,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.formatDate(invoice.invoiceDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context, statusColor),
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

            // ==================== المبالغ ====================
            Row(
              children: [
                Expanded(
                  child: _amountItem(
                    context,
                    'الإجمالي',
                    invoice.total,
                    AppTheme.primaryColor,
                    bold: true,
                  ),
                ),
                Expanded(
                  child: _amountItem(
                    context,
                    'المدفوع',
                    invoice.paidAmount,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _amountItem(
                    context,
                    'المتبقي',
                    invoice.dueAmount,
                    invoice.dueAmount > 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                  ),
                ),
              ],
            ),

            // ==================== تفاصيل إضافية ====================
            if (invoice.status == 'partial' && invoice.dueAmount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pending_actions,
                      size: 14,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        invoice.expectedPaymentDate != null
                            ? 'متبقي ${Helpers.formatCurrency(invoice.dueAmount)} • '
                                'السداد: ${Helpers.formatDate(invoice.expectedPaymentDate)}'
                            : 'متبقي ${Helpers.formatCurrency(invoice.dueAmount)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================== عدد البنود ====================
            if (invoice.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${invoice.items.length} بند',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        invoice.statusLabelAr,
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
    double value,
    Color color, {
    bool bold = false,
  }) {
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
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return AppTheme.textSecondary;
      case 'quote':
        return AppTheme.infoColor;
      case 'confirmed':
        return AppTheme.primaryColor;
      case 'paid':
        return AppTheme.successColor;
      case 'partial':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit_note;
      case 'quote':
        return Icons.request_quote;
      case 'confirmed':
        return Icons.verified;
      case 'paid':
        return Icons.check_circle;
      case 'partial':
        return Icons.pending_actions;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

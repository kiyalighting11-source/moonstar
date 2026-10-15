// lib/features/customers/presentation/widgets/customer_invoices_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../../invoices/providers/invoices_provider.dart';

class CustomerInvoicesSection extends ConsumerWidget {
  final String customerId;

  const CustomerInvoicesSection({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));
    final isDark = AppTheme.isDark(context);

    return invoicesAsync.when(
      loading: () => _buildLoading(context),
      error: (e, _) => _buildError(context, ref, e),
      data: (invoices) {
        if (invoices.isEmpty) {
          return _buildEmpty(context);
        }

        final stats = _calculateStats(invoices);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151A23) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الفواتير',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${invoices.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'تحديث',
                    onPressed: () =>
                        ref.invalidate(customerInvoicesProvider(customerId)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ===== إحصائيات =====
              _buildStats(context, stats, isDark),

              const SizedBox(height: 16),

              // ===== قائمة الفواتير =====
              ...invoices.map((invoice) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _invoiceTile(context, invoice, isDark),
                  )),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // Widgets
  // =====================================================

  Widget _buildStats(
    BuildContext context,
    Map<String, double> stats,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _statBox(
            context,
            'الإجمالي',
            Helpers.formatCurrency(stats['total'] ?? 0, decimals: 0),
            AppTheme.primaryColor,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            context,
            'المدفوع',
            Helpers.formatCurrency(stats['paid'] ?? 0, decimals: 0),
            AppTheme.successColor,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            context,
            'المتبقي',
            Helpers.formatCurrency(stats['due'] ?? 0, decimals: 0),
            AppTheme.errorColor,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _statBox(
    BuildContext context,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
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

  Widget _invoiceTile(
    BuildContext context,
    InvoiceModel invoice,
    bool isDark,
  ) {
    final statusColor = _statusColor(invoice.status);

    return InkWell(
      onTap: () => context.go('/invoices/${invoice.id}'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.03) : AppTheme.lightBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== الصف الأول =====
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _statusIcon(invoice.status),
                    color: statusColor,
                    size: 16,
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
                              invoice.invoiceNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (invoice.isSaleReturn)
                            _miniBadge(
                              'مرتجع',
                              AppTheme.errorColor,
                            )
                          else if (invoice.isQuote)
                            _miniBadge(
                              'عرض سعر',
                              AppTheme.infoColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.formatDate(invoice.invoiceDate),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge الحالة
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    invoice.statusLabelAr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.dividerColor,
            ),
            const SizedBox(height: 8),

            // ===== المبالغ =====
            Row(
              children: [
                Expanded(
                  child: _amountItem(
                    context,
                    'الإجمالي',
                    invoice.total,
                    AppTheme.textColor(context),
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
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
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
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(
            Helpers.formatCurrency(value, decimals: 0),
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

  Widget _buildLoading(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'مفيش فواتير لسه',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أول فاتورة للعميل ده هتظهر هنا',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object e) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'فشل تحميل الفواتير',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$e',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                ref.invalidate(customerInvoicesProvider(customerId)),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Helpers
  // =====================================================

  Map<String, double> _calculateStats(List<InvoiceModel> invoices) {
    double total = 0;
    double paid = 0;
    double due = 0;

    for (final inv in invoices) {
      // نستبعد الملغية والمسودات
      if (inv.isCancelled || inv.isDraft) continue;
      total += inv.total;
      paid += inv.paidAmount;
      due += inv.dueAmount;
    }

    return {'total': total, 'paid': paid, 'due': due};
  }

  Color _statusColor(String status) {
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

  IconData _statusIcon(String status) {
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

// lib/features/invoices/presentation/screens/invoice_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../printing/widgets/pdf_action_sheet.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_model.dart';
import '../../providers/invoices_provider.dart';
import '../widgets/payment_form_sheet.dart';

class InvoiceDetailsScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isValidUuid(invoiceId)) {
      return _buildInvalidId(context);
    }

    final invoiceAsync = ref.watch(invoiceByIdProvider(invoiceId));
    final roleCode = ref.watch(currentRoleProvider);
    final canEdit = roleCode == AppConstants.roleAdmin ||
        roleCode == AppConstants.roleManager ||
        roleCode == AppConstants.roleCashier;

    return invoiceAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        appBar: DashboardAppBar(
          title: 'تفاصيل البيان',
          actions: [ThemeToggleButton()],
        ),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const DashboardAppBar(
          title: 'تفاصيل البيان',
          actions: [ThemeToggleButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ),
      ),
      data: (invoice) {
        if (invoice == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: const DashboardAppBar(
              title: 'تفاصيل البيان',
              actions: [ThemeToggleButton()],
            ),
            body: Center(
              child: Text(
                'البيان غير موجود',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: DashboardAppBar(
            title: 'تفاصيل البيان',
            actions: [
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'طباعة / مشاركة',
                onPressed: () => _showPdfActions(context, invoice),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'تعديل',
                  onPressed: () => context.go('/invoices/edit/$invoiceId'),
                ),
            ],
          ),
          body: _buildContent(context, ref, invoice, canEdit),
        );
      },
    );
  }

  void _showPdfActions(BuildContext context, InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PdfActionSheet(invoice: invoice),
    );
  }

  Widget _buildInvalidId(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'تفاصيل البيان',
        actions: [ThemeToggleButton()],
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
                'البيان غير موجود',
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
    InvoiceModel invoice,
    bool canEdit,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(invoiceByIdProvider(invoiceId));
        ref.invalidate(invoicePaymentsProvider(invoiceId));
        await ref.read(invoiceByIdProvider(invoiceId).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, invoice),
          const SizedBox(height: 16),
          _buildCustomerSection(context, invoice),
          const SizedBox(height: 12),
          _buildDatesSection(context, invoice),
          const SizedBox(height: 12),
          _buildItemsSection(context, invoice),
          const SizedBox(height: 12),
          _buildTotalsSection(context, invoice),
          const SizedBox(height: 12),
          _buildPaymentsSection(context, ref, invoice, canEdit),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _section(context, 'ملاحظات', [
              Text(
                invoice.notes!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textColor(context),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 24),
          _buildActions(context, ref, invoice, canEdit),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =====================================================
  // Header
  // =====================================================
  Widget _buildHeader(BuildContext context, InvoiceModel invoice) {
    final color = _statusColor(invoice.status);
    final title = invoice.title ?? 'بيان';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(invoice.status),
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.invoiceNumber,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _badge(invoice.typeLabelAr, AppTheme.infoColor),
                        const SizedBox(width: 6),
                        _badge(invoice.statusLabelAr, color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // =====================================================
  // Sections
  // =====================================================
  Widget _buildCustomerSection(BuildContext context, InvoiceModel invoice) {
    return _section(context, 'العميل', [
      _row(context, Icons.person, 'الاسم', invoice.customerName ?? '—'),
      if (invoice.customerPhone != null && invoice.customerPhone!.isNotEmpty)
        _row(context, Icons.phone, 'الموبايل', invoice.customerPhone!),
      if (invoice.warehouseName != null && invoice.warehouseName!.isNotEmpty)
        _row(context, Icons.warehouse, 'المخزن', invoice.warehouseName!),
    ]);
  }

  Widget _buildDatesSection(BuildContext context, InvoiceModel invoice) {
    return _section(context, 'التواريخ', [
      _row(
        context,
        Icons.calendar_today,
        'تاريخ البيان',
        Helpers.formatDate(invoice.invoiceDate),
      ),
      if (invoice.dueDate != null)
        _row(
          context,
          Icons.event,
          'تاريخ الاستحقاق',
          Helpers.formatDate(invoice.dueDate),
        ),
      if (invoice.expectedPaymentDate != null)
        _row(
          context,
          Icons.schedule,
          'السداد المتوقع',
          Helpers.formatDate(invoice.expectedPaymentDate),
        ),
    ]);
  }

  Widget _buildItemsSection(BuildContext context, InvoiceModel invoice) {
    if (invoice.items.isEmpty) {
      return _section(context, 'البنود', [
        Text(
          'مفيش بنود',
          style: TextStyle(color: AppTheme.textSecondaryColor(context)),
        ),
      ]);
    }

    return _section(context, 'البنود', [
      ...invoice.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: item.isStockItem
                        ? AppTheme.infoColor.withValues(alpha: 0.15)
                        : AppTheme.warningColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    item.isStockItem ? Icons.inventory_2 : Icons.work_outline,
                    size: 14,
                    color: item.isStockItem
                        ? AppTheme.infoColor
                        : AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.quantity} × ${Helpers.formatCurrency(item.unitPrice)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Helpers.formatCurrency(item.quantity * item.unitPrice),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
          )),
    ]);
  }

  Widget _buildTotalsSection(BuildContext context, InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _totalRow(
              context, 'المجموع الفرعي', invoice.subtotal, Colors.white70),
          if (invoice.totalExtra > 0)
            _totalRow(
                context, 'بنود إضافية', invoice.totalExtra, Colors.white70),
          if (invoice.discount > 0)
            _totalRow(
                context, 'الخصم', -invoice.discount, Colors.yellow.shade200),
          if (invoice.tax > 0)
            _totalRow(context, 'الضريبة', invoice.tax, Colors.white70),
          const Divider(color: Colors.white30, height: 20),
          _totalRow(
            context,
            'الإجمالي',
            invoice.total,
            Colors.white,
            bold: true,
            big: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
    bool canEdit,
  ) {
    return _section(context, 'الدفعات', [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.isDark(context)
              ? Colors.white.withValues(alpha: 0.05)
              : AppTheme.lightBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: _paymentStat(
                context,
                'المدفوع',
                invoice.paidAmount,
                AppTheme.successColor,
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: AppTheme.dividerColor,
            ),
            Expanded(
              child: _paymentStat(
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
      ),
      if (invoice.expectedPaymentDate != null && invoice.dueAmount > 0) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.warningColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.warningColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'السداد المتوقع: '
                  '${Helpers.formatDate(invoice.expectedPaymentDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
      _buildPaymentsList(context, ref, invoice),
      if (canEdit && invoice.dueAmount > 0 && !invoice.isCancelled) ...[
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddPayment(context, ref, invoice),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة دفعة'),
          ),
        ),
      ],
    ]);
  }

  Widget _buildPaymentsList(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) {
    final paymentsAsync = ref.watch(invoicePaymentsProvider(invoice.id));

    return paymentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('خطأ: $e'),
      data: (payments) {
        if (payments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'مفيش دفعات لسه',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          );
        }
        return Column(
          children: payments.map((p) => _paymentTile(context, p)).toList(),
        );
      },
    );
  }

  Widget _paymentTile(BuildContext context, PaymentModel payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 14,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Helpers.formatCurrency(payment.amount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${payment.methodLabelAr} • '
                  '${Helpers.formatDate(payment.paymentDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentStat(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          Helpers.formatCurrency(value, decimals: 0),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
    bool canEdit,
  ) {
    if (!canEdit) return const SizedBox.shrink();

    final actions = <Widget>[];

    if (invoice.isDraft) {
      actions.add(_actionButton(
        context,
        'تأكيد البيان',
        Icons.check_circle,
        AppTheme.successColor,
        () => _confirm(context, ref, invoice),
      ));
      actions.add(const SizedBox(height: 8));
      actions.add(_actionButton(
        context,
        'حذف البيان',
        Icons.delete,
        AppTheme.errorColor,
        () => _delete(context, ref, invoice),
        outlined: true,
      ));
    } else if (invoice.isConfirmed || invoice.isPartial) {
      actions.add(_actionButton(
        context,
        'إلغاء البيان',
        Icons.cancel,
        AppTheme.errorColor,
        () => _cancel(context, ref, invoice),
        outlined: true,
      ));
    }

    return Column(children: actions);
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    if (outlined) {
      return SizedBox(
        height: 48,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
          ),
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
    }
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'تأكيد البيان',
      message: 'هيتم خصم الكميات من المخزون تلقائياً.\n\nمتأكد؟',
      confirmText: 'تأكيد',
    );
    if (!confirm) return;

    final result = await ref
        .read(invoicesControllerProvider.notifier)
        .confirmInvoice(invoice.id);

    if (!context.mounted) return;
    if (result != null) {
      Helpers.showSuccess(context, 'تم تأكيد البيان ✅');
    } else {
      Helpers.showError(context, 'فشل التأكيد');
    }
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'إلغاء البيان',
      message: 'هل تريد إلغاء البيان؟',
      confirmText: 'إلغاء البيان',
      confirmColor: AppTheme.errorColor,
    );
    if (!confirm) return;

    final result = await ref
        .read(invoicesControllerProvider.notifier)
        .cancelInvoice(invoice.id);

    if (!context.mounted) return;
    if (result != null) {
      Helpers.showSuccess(context, 'تم إلغاء البيان');
    } else {
      Helpers.showError(context, 'فشل الإلغاء');
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'حذف البيان',
      message: 'هل أنت متأكد من الحذف؟',
      confirmText: 'حذف',
      confirmColor: AppTheme.errorColor,
    );
    if (!confirm) return;

    final success = await ref
        .read(invoicesControllerProvider.notifier)
        .deleteInvoice(invoice.id);

    if (!context.mounted) return;
    if (success) {
      Helpers.showSuccess(context, 'تم الحذف');
      context.go('/invoices');
    } else {
      Helpers.showError(context, 'فشل الحذف');
    }
  }

  void _showAddPayment(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentFormSheet(
        invoiceId: invoice.id,
        maxAmount: invoice.dueAmount,
      ),
    );
  }

  // =====================================================
  // Widgets
  // =====================================================
  Widget _section(BuildContext context, String title, List<Widget> children) {
    final isDark = AppTheme.isDark(context);

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

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondaryColor(context)),
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
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    double value,
    Color color, {
    bool bold = false,
    bool big = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: big ? 16 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            Helpers.formatCurrency(value),
            style: TextStyle(
              color: color,
              fontSize: big ? 20 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool _isValidUuid(String s) => _uuidRegex.hasMatch(s);
}

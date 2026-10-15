// lib/features/printing/widgets/pdf_action_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/settings_model.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../invoices/data/models/invoice_model.dart';
import '../services/invoice_pdf_service.dart';
import '../services/pdf_share_service.dart';

class PdfActionSheet extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const PdfActionSheet({
    super.key,
    required this.invoice,
  });

  @override
  ConsumerState<PdfActionSheet> createState() => _PdfActionSheetState();
}

class _PdfActionSheetState extends ConsumerState<PdfActionSheet> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // العنوان
          Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: AppTheme.primaryColor,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خيارات البيان',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    Text(
                      widget.invoice.invoiceNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'جارٍ تجهيز الملف...',
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                ],
              ),
            )
          else ...[
            _actionTile(
              context: context,
              icon: Icons.visibility,
              title: 'معاينة',
              subtitle: 'عرض البيان قبل الطباعة',
              color: AppTheme.infoColor,
              onTap: _preview,
            ),
            _actionTile(
              context: context,
              icon: Icons.print,
              title: 'طباعة',
              subtitle: 'طباعة مباشرة',
              color: AppTheme.primaryColor,
              onTap: _print,
            ),
            _actionTile(
              context: context,
              icon: Icons.share,
              title: 'مشاركة',
              subtitle: 'واتساب / إيميل / أي تطبيق',
              color: AppTheme.successColor,
              onTap: _share,
            ),
            _actionTile(
              context: context,
              icon: Icons.chat,
              title: 'إرسال على واتساب',
              subtitle: widget.invoice.customerPhone != null
                  ? 'إلى ${widget.invoice.customerPhone}'
                  : 'بدون رقم محدد',
              color: const Color(0xFF25D366),
              onTap: _shareWhatsApp,
            ),
            _actionTile(
              context: context,
              icon: Icons.email,
              title: 'إرسال على إيميل',
              subtitle: 'فتح تطبيق الإيميل',
              color: AppTheme.errorColor,
              onTap: _shareEmail,
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.textSecondaryColor(context),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Actions
  // =====================================================
  Future<SettingsModel?> _getSettings() async {
    return await ref.read(settingsRepositoryProvider).getSettings();
  }

  void _startGenerating() {
    if (mounted) setState(() => _isGenerating = true);
  }

  void _stopGenerating() {
    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _preview() async {
    _startGenerating();
    try {
      final settings = await _getSettings();
      final bytes = await InvoicePdfService.build(
        invoice: widget.invoice,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.previewPdf(
        bytes: bytes,
        jobName: widget.invoice.invoiceNumber,
      );
    } catch (e) {
      if (!mounted) return;
      _stopGenerating();
      Helpers.showError(context, 'فشل التوليد: $e');
    }
  }

  Future<void> _print() async {
    _startGenerating();
    try {
      final settings = await _getSettings();
      final bytes = await InvoicePdfService.build(
        invoice: widget.invoice,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.printPdf(
        bytes: bytes,
        jobName: widget.invoice.invoiceNumber,
      );
    } catch (e) {
      if (!mounted) return;
      _stopGenerating();
      Helpers.showError(context, 'فشل الطباعة: $e');
    }
  }

  Future<void> _share() async {
    _startGenerating();
    try {
      final settings = await _getSettings();
      final bytes = await InvoicePdfService.build(
        invoice: widget.invoice,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.sharePdf(
        bytes: bytes,
        filename: '${widget.invoice.invoiceNumber}.pdf',
        text: PdfShareService.buildShareText(widget.invoice),
      );
    } catch (e) {
      if (!mounted) return;
      _stopGenerating();
      Helpers.showError(context, 'فشل المشاركة: $e');
    }
  }

  Future<void> _shareWhatsApp() async {
    final phone = widget.invoice.customerPhone;
    if (phone == null || phone.isEmpty) {
      Helpers.showError(context, 'مفيش رقم موبايل للعميل');
      return;
    }

    _startGenerating();
    try {
      final settings = await _getSettings();
      final bytes = await InvoicePdfService.build(
        invoice: widget.invoice,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.shareViaWhatsApp(
        bytes: bytes,
        filename: '${widget.invoice.invoiceNumber}.pdf',
        phone: phone,
        invoiceNumber: widget.invoice.invoiceNumber,
        total: Helpers.formatCurrency(widget.invoice.total),
      );
    } catch (e) {
      if (!mounted) return;
      _stopGenerating();
      Helpers.showError(context, 'فشل الإرسال: $e');
    }
  }

  Future<void> _shareEmail() async {
    _startGenerating();
    try {
      final settings = await _getSettings();
      final bytes = await InvoicePdfService.build(
        invoice: widget.invoice,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.sharePdf(
        bytes: bytes,
        filename: '${widget.invoice.invoiceNumber}.pdf',
        text: 'بيان رقم ${widget.invoice.invoiceNumber}',
      );
    } catch (e) {
      if (!mounted) return;
      _stopGenerating();
      Helpers.showError(context, 'فشل الإرسال: $e');
    }
  }
}

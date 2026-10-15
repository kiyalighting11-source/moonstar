// lib/features/printing/widgets/maintenance_pdf_action_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/settings_model.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../maintenance/data/models/maintenance_model.dart';
import '../services/maintenance_pdf_service.dart';
import '../services/pdf_share_service.dart';

class MaintenancePdfActionSheet extends ConsumerStatefulWidget {
  final MaintenanceModel ticket;

  const MaintenancePdfActionSheet({
    super.key,
    required this.ticket,
  });

  @override
  ConsumerState<MaintenancePdfActionSheet> createState() =>
      _MaintenancePdfActionSheetState();
}

class _MaintenancePdfActionSheetState
    extends ConsumerState<MaintenancePdfActionSheet> {
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
                Icons.build_circle,
                color: AppTheme.primaryColor,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خيارات التذكرة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    Text(
                      widget.ticket.ticketNumber,
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
              subtitle: 'عرض التذكرة قبل الطباعة',
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
              subtitle: widget.ticket.customerPhone != null
                  ? 'إلى ${widget.ticket.customerPhone}'
                  : 'بدون رقم محدد',
              color: const Color(0xFF25D366),
              onTap: _shareWhatsApp,
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

  String get _fileName => 'ticket_${widget.ticket.ticketNumber}.pdf';

  Future<void> _preview() async {
    _startGenerating();
    try {
      final settings = await _getSettings();
      final bytes = await MaintenancePdfService.build(
        ticket: widget.ticket,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.previewPdf(
        bytes: bytes,
        jobName: widget.ticket.ticketNumber,
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
      final bytes = await MaintenancePdfService.build(
        ticket: widget.ticket,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.printPdf(
        bytes: bytes,
        jobName: widget.ticket.ticketNumber,
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
      final bytes = await MaintenancePdfService.build(
        ticket: widget.ticket,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.sharePdf(
        bytes: bytes,
        filename: _fileName,
        text: _buildShareText(),
      );
    } catch (e) {
      if (!mounted) return;
      _stopGenerating();
      Helpers.showError(context, 'فشل المشاركة: $e');
    }
  }

  Future<void> _shareWhatsApp() async {
    final phone = widget.ticket.customerPhone;
    if (phone == null || phone.isEmpty) {
      Helpers.showError(context, 'مفيش رقم موبايل للعميل');
      return;
    }

    _startGenerating();
    try {
      final settings = await _getSettings();
      final bytes = await MaintenancePdfService.build(
        ticket: widget.ticket,
        settings: settings,
      );
      if (!mounted) return;
      _stopGenerating();
      await PdfShareService.shareViaWhatsApp(
        bytes: bytes,
        filename: _fileName,
        phone: phone,
        invoiceNumber: widget.ticket.ticketNumber,
        total: Helpers.formatCurrency(widget.ticket.totalCost),
      );
    } catch (e) {
      if (!mounted) return;
      _stopGenerating();
      Helpers.showError(context, 'فشل الإرسال: $e');
    }
  }

  String _buildShareText() {
    final t = widget.ticket;
    final buffer = StringBuffer();
    buffer.writeln('🔧 *تذكرة صيانة* 🔧');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 رقم: ${t.ticketNumber}');
    if (t.customerName != null) {
      buffer.writeln('👤 العميل: ${t.customerName}');
    }
    buffer.writeln('📦 الأجهزة: ${t.devicesCount}');
    if (t.partsCount > 0) {
      buffer.writeln('🔩 القطع: ${t.partsCount}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 الإجمالي: ${t.totalCost} ج.م');
    if (t.paidAmount > 0) {
      buffer.writeln('✅ المدفوع: ${t.paidAmount} ج.م');
    }
    if (t.dueAmount > 0) {
      buffer.writeln('⚠️ المتبقي: ${t.dueAmount} ج.م');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('شكراً لتعاملكم معنا 🌟');
    return buffer.toString();
  }
}

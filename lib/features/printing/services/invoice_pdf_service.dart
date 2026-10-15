// lib/features/printing/services/invoice_pdf_service.dart

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/models/settings_model.dart';
import '../../invoices/data/models/invoice_item_model.dart';
import '../../invoices/data/models/invoice_model.dart';

class InvoicePdfService {
  // =====================================================
  // الألوان
  // =====================================================
  static const PdfColor _primary = PdfColor.fromInt(0xFF6A1B9A);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFF9C4DCC);
  static const PdfColor _success = PdfColor.fromInt(0xFF43A047);
  static const PdfColor _warning = PdfColor.fromInt(0xFFFB8C00);
  static const PdfColor _error = PdfColor.fromInt(0xFFE53935);
  static const PdfColor _grey = PdfColor.fromInt(0xFF757575);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF5F5F5);

  // =====================================================
  // ⭐ أحجام الخطوط (متوازنة — واضحة + تدخل في صفحة)
  // =====================================================
  static const double _fsTitle = 18.0; // اسم الشركة
  static const double _fsSubTitle = 10.0; // العنوان الفرعي
  static const double _fsSmall = 9.5; // النصوص الصغيرة
  static const double _fsTiny = 8.5; // الجداول والتفاصيل
  static const double _fsBody = 10.5; // النصوص العادية
  static const double _fsSectionTitle = 11.5; // عناوين الأقسام

  // ⭐ هوامش
  static const double _margin = 22.0;
  static const double _gapXS = 2.5;
  static const double _gapS = 5.0;
  static const double _gapM = 8.0;

  // =====================================================
  // البناء — كل حاجة في صفحة واحدة
  // =====================================================
  static Future<Uint8List> build({
    required InvoiceModel invoice,
    required SettingsModel? settings,
  }) async {
    final font = await PdfGoogleFontsService.loadCairoFont();
    final fontBold = await PdfGoogleFontsService.loadCairoBoldFont();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margin),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ===== Header =====
            _buildHeader(invoice, settings),
            pw.SizedBox(height: _gapS),

            // ===== معلومات البيان =====
            _buildInvoiceInfo(invoice),
            pw.SizedBox(height: _gapS),

            // ===== العميل =====
            _buildCustomerInfo(invoice),
            pw.SizedBox(height: _gapM),

            // ===== جدول البنود =====
            _buildItemsTable(invoice),
            pw.SizedBox(height: _gapS),

            // ===== الملخص المالي =====
            _buildTotals(invoice),

            // ===== الدفعات =====
            if (invoice.payments.isNotEmpty) ...[
              pw.SizedBox(height: _gapS),
              _buildPayments(invoice),
            ],

            // ===== ملاحظات =====
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: _gapS),
              _buildNotes(invoice),
            ],

            // ===== دفع لأسفل عشان الفوتر =====
            pw.Spacer(),

            // ===== Footer =====
            _buildFooter(settings),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // =====================================================
  // Header
  // =====================================================
  static pw.Widget _buildHeader(
    InvoiceModel invoice,
    SettingsModel? settings,
  ) {
    final companyName = settings?.companyName ?? 'Moonstar';
    final companyPhone = settings?.companyPhone ?? '';
    final companyAddress = settings?.companyAddress ?? '';
    final companyEmail = settings?.companyEmail ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: _gapS),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primary, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // الشعار والاسم
          pw.Row(
            children: [
              pw.Container(
                width: 42,
                height: 42,
                decoration: pw.BoxDecoration(
                  color: _primary,
                  borderRadius: pw.BorderRadius.circular(21),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  companyName.isNotEmpty
                      ? companyName.substring(0, 1).toUpperCase()
                      : 'M',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: _gapS),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: const pw.TextStyle(
                      fontSize: _fsTitle,
                      fontWeight: pw.FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  pw.SizedBox(height: _gapXS),
                  pw.Text(
                    'نظام الفواتير الآلي',
                    style: const pw.TextStyle(
                      fontSize: _fsSubTitle,
                      color: _grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // معلومات الاتصال
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (companyPhone.isNotEmpty) _contactRow('ت', companyPhone),
              if (companyEmail.isNotEmpty) _contactRow('ب', companyEmail),
              if (companyAddress.isNotEmpty) _contactRow('ع', companyAddress),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _contactRow(String icon, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Text(
        '$icon: $text',
        style: const pw.TextStyle(
          fontSize: _fsSmall,
          color: _grey,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  // =====================================================
  // معلومات البيان
  // =====================================================
  static pw.Widget _buildInvoiceInfo(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(_gapS),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('رقم البيان:', invoice.invoiceNumber),
                pw.SizedBox(height: _gapXS),
                _infoRow('النوع:', invoice.typeLabelAr),
                pw.SizedBox(height: _gapXS),
                _infoRow(
                  'التاريخ:',
                  DateFormat('dd/MM/yyyy').format(invoice.invoiceDate),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('الحالة:', invoice.statusLabelAr),
                pw.SizedBox(height: _gapXS),
                _infoRow('طريقة الدفع:', invoice.paymentMethodLabelAr),
                if (invoice.dueDate != null) ...[
                  pw.SizedBox(height: _gapXS),
                  _infoRow(
                    'الاستحقاق:',
                    DateFormat('dd/MM/yyyy').format(invoice.dueDate!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: _fsSmall,
            color: _grey,
          ),
        ),
        pw.SizedBox(width: _gapS),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: _fsSmall,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // العميل
  // =====================================================
  static pw.Widget _buildCustomerInfo(InvoiceModel invoice) {
    final name = invoice.customerName ?? '—';
    final phone = invoice.customerPhone;

    return pw.Container(
      padding: const pw.EdgeInsets.all(_gapS),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primaryLight, width: 0.5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 3.5,
                height: 12,
                color: _primary,
              ),
              pw.SizedBox(width: _gapS),
              pw.Text(
                'بيانات العميل',
                style: const pw.TextStyle(
                  fontSize: _fsSectionTitle,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: _gapXS),
          pw.Row(
            children: [
              pw.Expanded(
                child: _infoRow('الاسم:', name),
              ),
              if (phone != null)
                pw.Expanded(
                  child: _infoRow('الموبايل:', phone),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // جدول البنود
  // =====================================================
  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 3.5,
              height: 12,
              color: _primary,
            ),
            pw.SizedBox(width: _gapS),
            pw.Text(
              'بنود البيان',
              style: const pw.TextStyle(
                fontSize: _fsSectionTitle,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: _gapXS),
        pw.Table(
          border: pw.TableBorder.all(color: _lightGrey, width: 0.4),
          columnWidths: {
            0: const pw.FlexColumnWidth(5),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.6),
            3: const pw.FlexColumnWidth(1.8),
          },
          children: [
            // الهيدر
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _primary),
              children: [
                _tableHeader('البند'),
                _tableHeader('الكمية'),
                _tableHeader('السعر'),
                _tableHeader('الإجمالي'),
              ],
            ),
            // البنود
            ...invoice.items.map((item) => _buildItemRow(item)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(_gapS),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: _fsSmall,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.TableRow _buildItemRow(InvoiceItemModel item) {
    return pw.TableRow(
      children: [
        _tableCell(
          item.displayName +
              (item.productSku != null ? ' (${item.productSku})' : ''),
          align: pw.TextAlign.right,
        ),
        _tableCell(_formatQty(item.quantity)),
        _tableCell(_formatNumber(item.unitPrice)),
        _tableCell(_formatNumber(item.quantity * item.unitPrice)),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: _gapS,
        vertical: _gapXS,
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: _fsTiny),
        textAlign: align,
      ),
    );
  }

  // =====================================================
  // الملخص المالي
  // =====================================================
  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 200,
          child: pw.Column(
            children: [
              _totalRow('المجموع الفرعي', invoice.subtotal),
              if (invoice.totalExtra > 0)
                _totalRow('بنود إضافية', invoice.totalExtra),
              if (invoice.discount > 0)
                _totalRow(
                  'الخصم',
                  -invoice.discount,
                  color: _warning,
                ),
              if (invoice.tax > 0) _totalRow('الضريبة', invoice.tax),
              pw.Divider(height: 5, thickness: 0.4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: _gapS,
                  vertical: _gapS,
                ),
                decoration: pw.BoxDecoration(
                  color: _primary,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'الإجمالي',
                      style: const pw.TextStyle(
                        fontSize: _fsBody,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      _formatNumber(invoice.total),
                      style: const pw.TextStyle(
                        fontSize: _fsBody,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, double value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: _fsSmall, color: _grey),
          ),
          pw.Text(
            _formatNumber(value),
            style: pw.TextStyle(
              fontSize: _fsSmall,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // الدفعات
  // =====================================================
  static pw.Widget _buildPayments(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(_gapS),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 3.5,
                height: 12,
                color: _success,
              ),
              pw.SizedBox(width: _gapS),
              pw.Text(
                'الدفعات',
                style: const pw.TextStyle(
                  fontSize: _fsSectionTitle,
                  fontWeight: pw.FontWeight.bold,
                  color: _success,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: _gapXS),
          // ملخص
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('المدفوع', invoice.paidAmount, _success),
              _summaryBox(
                'المتبقي',
                invoice.dueAmount,
                invoice.dueAmount > 0 ? _error : _success,
              ),
            ],
          ),
          pw.SizedBox(height: _gapXS),
          // التفاصيل
          ...invoice.payments.map((p) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${p.methodLabelAr} - '
                      '${DateFormat('dd/MM/yyyy').format(p.paymentDate)}',
                      style: const pw.TextStyle(
                        fontSize: _fsTiny,
                        color: _grey,
                      ),
                    ),
                    pw.Text(
                      _formatNumber(p.amount),
                      style: const pw.TextStyle(
                        fontSize: _fsTiny,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(String label, double value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: _gapS,
        vertical: _gapXS,
      ),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: color, width: 0.4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: _fsTiny, color: _grey),
          ),
          pw.SizedBox(height: 1.5),
          pw.Text(
            _formatNumber(value),
            style: pw.TextStyle(
              fontSize: _fsBody,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ملاحظات
  // =====================================================
  static pw.Widget _buildNotes(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(_gapS),
      decoration: pw.BoxDecoration(
        color: PdfColors.yellow50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.yellow200, width: 0.4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 3.5, height: 12, color: _warning),
              pw.SizedBox(width: _gapS),
              pw.Text(
                'ملاحظات',
                style: const pw.TextStyle(
                  fontSize: _fsSectionTitle,
                  fontWeight: pw.FontWeight.bold,
                  color: _warning,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: _gapXS),
          pw.Text(
            invoice.notes!,
            style: const pw.TextStyle(fontSize: _fsSmall),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Footer
  // =====================================================
  static pw.Widget _buildFooter(SettingsModel? settings) {
    final companyName = settings?.companyName ?? 'Moonstar';
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: _gapS),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _lightGrey, width: 0.4),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'شكراً لتعاملكم معنا',
            style: const pw.TextStyle(
              fontSize: _fsSmall,
              color: _primary,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '$companyName ERP',
            style: const pw.TextStyle(fontSize: _fsTiny, color: _grey),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Helpers
  // =====================================================
  static String _formatNumber(double value) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(value);
  }

  static String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }
}

// =====================================================
// Google Fonts Helper (Cairo للعربي)
// =====================================================
class PdfGoogleFontsService {
  static pw.Font? _cairoFont;
  static pw.Font? _cairoBoldFont;

  static Future<pw.Font> loadCairoFont() async {
    if (_cairoFont != null) return _cairoFont!;
    try {
      _cairoFont = await PdfGoogleFonts.cairoRegular();
    } catch (_) {
      _cairoFont = pw.Font.helvetica();
    }
    return _cairoFont!;
  }

  static Future<pw.Font> loadCairoBoldFont() async {
    if (_cairoBoldFont != null) return _cairoBoldFont!;
    try {
      _cairoBoldFont = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      _cairoBoldFont = pw.Font.helveticaBold();
    }
    return _cairoBoldFont!;
  }
}

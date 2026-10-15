// lib/features/printing/services/maintenance_pdf_service.dart

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/settings_model.dart';
import '../../maintenance/data/models/maintenance_model.dart';
import 'invoice_pdf_service.dart'; // ⭐ نستخدم PdfGoogleFontsService الموجود

class MaintenancePdfService {
  // =====================================================
  // الألوان
  // =====================================================
  static const PdfColor _primary = PdfColor.fromInt(0xFF6A1B9A);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFF9C4DCC);
  static const PdfColor _success = PdfColor.fromInt(0xFF43A047);
  static const PdfColor _warning = PdfColor.fromInt(0xFFFB8C00);
  static const PdfColor _error = PdfColor.fromInt(0xFFE53935);
  static const PdfColor _info = PdfColor.fromInt(0xFF00ACC1);
  static const PdfColor _grey = PdfColor.fromInt(0xFF757575);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF5F5F5);

  // =====================================================
  // أحجام الخطوط
  // =====================================================
  static const double _fsTitle = 18.0;
  static const double _fsSubTitle = 10.0;
  static const double _fsSmall = 9.5;
  static const double _fsTiny = 8.5;
  static const double _fsBody = 10.5;
  static const double _fsSectionTitle = 11.5;

  // هوامش
  static const double _margin = 22.0;
  static const double _gapXS = 2.5;
  static const double _gapS = 5.0;
  static const double _gapM = 8.0;

  // =====================================================
  // البناء
  // =====================================================
  static Future<Uint8List> build({
    required MaintenanceModel ticket,
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
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margin),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) => [
          // ===== Header =====
          _buildHeader(settings),
          pw.SizedBox(height: _gapS),

          // ===== معلومات التذكرة =====
          _buildTicketInfo(ticket),
          pw.SizedBox(height: _gapS),

          // ===== العميل =====
          _buildCustomerInfo(ticket),
          pw.SizedBox(height: _gapM),

          // ===== الفني =====
          if (ticket.hasTechnician) ...[
            _buildTechnicianInfo(ticket),
            pw.SizedBox(height: _gapS),
          ],

          // ===== الأجهزة =====
          if (ticket.devices.isNotEmpty) ...[
            _buildDevicesSection(ticket),
            pw.SizedBox(height: _gapS),
          ],

          // ===== قطع الغيار =====
          if (ticket.parts.isNotEmpty) ...[
            _buildPartsSection(ticket),
            pw.SizedBox(height: _gapS),
          ],

          // ===== الملخص المالي =====
          _buildTotals(ticket),

          // ===== ملاحظات =====
          if (ticket.notes != null && ticket.notes!.isNotEmpty) ...[
            pw.SizedBox(height: _gapS),
            _buildNotes(ticket),
          ],

          // ===== Footer =====
          pw.SizedBox(height: _gapM),
          _buildFooter(settings),
        ],
      ),
    );

    return doc.save();
  }

  // =====================================================
  // Header
  // =====================================================
  static pw.Widget _buildHeader(SettingsModel? settings) {
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
                    'نظام إدارة الصيانة',
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
  // معلومات التذكرة
  // =====================================================
  static pw.Widget _buildTicketInfo(MaintenanceModel ticket) {
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
                _infoRow('رقم التذكرة:', ticket.ticketNumber),
                pw.SizedBox(height: _gapXS),
                _infoRow('الحالة:', _statusLabelAr(ticket.status)),
                pw.SizedBox(height: _gapXS),
                _infoRow('الأولوية:', _priorityLabelAr(ticket.priority)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow(
                  'تاريخ الاستلام:',
                  ticket.receivedAt != null
                      ? DateFormat('dd/MM/yyyy').format(ticket.receivedAt!)
                      : '—',
                ),
                pw.SizedBox(height: _gapXS),
                if (ticket.expectedDelivery != null)
                  _infoRow(
                    'التسليم المتوقع:',
                    DateFormat('dd/MM/yyyy').format(ticket.expectedDelivery!),
                  ),
                if (ticket.deliveredAt != null) ...[
                  pw.SizedBox(height: _gapXS),
                  _infoRow(
                    'تاريخ التسليم:',
                    DateFormat('dd/MM/yyyy').format(ticket.deliveredAt!),
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
  static pw.Widget _buildCustomerInfo(MaintenanceModel ticket) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(_gapS),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primaryLight, width: 0.5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitleBar('بيانات العميل', _primary),
          pw.SizedBox(height: _gapXS),
          pw.Row(
            children: [
              pw.Expanded(
                child: _infoRow('الاسم:', ticket.customerName ?? '—'),
              ),
              if (ticket.customerPhone != null)
                pw.Expanded(
                  child: _infoRow('الموبايل:', ticket.customerPhone!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // الفني
  // =====================================================
  static pw.Widget _buildTechnicianInfo(MaintenanceModel ticket) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(_gapS),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _info, width: 0.5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitleBar('الفني المسؤول', _info),
          pw.SizedBox(height: _gapXS),
          _infoRow('الاسم:', ticket.technicianName ?? '—'),
        ],
      ),
    );
  }

  // =====================================================
  // الأجهزة
  // =====================================================
  static pw.Widget _buildDevicesSection(MaintenanceModel ticket) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitleBar(
          'الأجهزة (${ticket.devicesCount})',
          _warning,
        ),
        pw.SizedBox(height: _gapXS),
        ...ticket.devices.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final device = entry.value;
          return _buildDeviceCard(device, index);
        }),
      ],
    );
  }

  static pw.Widget _buildDeviceCard(dynamic device, int index) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: _gapS),
      padding: const pw.EdgeInsets.all(_gapS),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header: رقم + اسم + سعر
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: _warning,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  '$index',
                  style: const pw.TextStyle(
                    fontSize: _fsTiny,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: _gapS),
              pw.Expanded(
                child: pw.Text(
                  device.displayName as String,
                  style: const pw.TextStyle(
                    fontSize: _fsBody,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if ((device.price as double) > 0)
                pw.Text(
                  _formatNumber(device.price as double),
                  style: const pw.TextStyle(
                    fontSize: _fsBody,
                    fontWeight: pw.FontWeight.bold,
                    color: _success,
                  ),
                ),
            ],
          ),

          // Serial
          if (device.hasSerial == true) ...[
            pw.SizedBox(height: _gapXS),
            pw.Text(
              'Serial: ${device.serialNumber}',
              style: const pw.TextStyle(
                fontSize: _fsTiny,
                color: _grey,
              ),
            ),
          ],

          // المشكلة
          if ((device.issueDescription as String).isNotEmpty) ...[
            pw.SizedBox(height: _gapXS),
            _labeledText(
              'المشكلة:',
              device.issueDescription as String,
              _error,
            ),
          ],

          // اللي اتعمل
          if (device.resolution != null &&
              (device.resolution as String).isNotEmpty) ...[
            pw.SizedBox(height: _gapXS),
            _labeledText(
              'اللي اتعمل:',
              device.resolution as String,
              _success,
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // قطع الغيار
  // =====================================================
  static pw.Widget _buildPartsSection(MaintenanceModel ticket) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitleBar('قطع الغيار (${ticket.partsCount})', _info),
        pw.SizedBox(height: _gapXS),
        pw.Table(
          border: pw.TableBorder.all(color: _lightGrey, width: 0.4),
          columnWidths: {
            0: const pw.FlexColumnWidth(5),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _info),
              children: [
                _tableHeader('القطعة'),
                _tableHeader('الكمية'),
                _tableHeader('السعر'),
                _tableHeader('الإجمالي'),
              ],
            ),
            // Rows
            ...ticket.parts.map(
              (part) => pw.TableRow(
                children: [
                  _tableCell(
                    part.productName ?? '—',
                    align: pw.TextAlign.right,
                  ),
                  _tableCell(_formatQty(part.quantity)),
                  _tableCell(_formatNumber(part.unitPrice)),
                  _tableCell(_formatNumber(part.total)),
                ],
              ),
            ),
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
  static pw.Widget _buildTotals(MaintenanceModel ticket) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 220,
          child: pw.Column(
            children: [
              if (ticket.devicesPrice > 0)
                _totalRow(
                  'الأجهزة (${ticket.devicesCount})',
                  ticket.devicesPrice,
                ),
              if (ticket.partsCost > 0)
                _totalRow(
                  'قطع الغيار (${ticket.partsCount})',
                  ticket.partsCost,
                ),
              if (ticket.laborCost > 0)
                _totalRow('أجرة الصيانة', ticket.laborCost),
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
                      _formatNumber(ticket.totalCost),
                      style: const pw.TextStyle(
                        fontSize: _fsBody,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: _gapXS),
              _totalRow(
                'المدفوع',
                ticket.paidAmount,
                color: _success,
              ),
              _totalRow(
                'المتبقي',
                ticket.dueAmount,
                color: ticket.dueAmount > 0 ? _error : _success,
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
  // ملاحظات
  // =====================================================
  static pw.Widget _buildNotes(MaintenanceModel ticket) {
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
          _sectionTitleBar('ملاحظات', _warning),
          pw.SizedBox(height: _gapXS),
          pw.Text(
            ticket.notes!,
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
  static pw.Widget _sectionTitleBar(String title, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 3.5, height: 12, color: color),
        pw.SizedBox(width: _gapS),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: _fsSectionTitle,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _labeledText(String label, String value, PdfColor color) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 55,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: _fsTiny,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: _fsTiny, color: _grey),
          ),
        ),
      ],
    );
  }

  static String _formatNumber(double value) {
    return NumberFormat('#,##0.00').format(value);
  }

  static String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toStringAsFixed(0);
    return qty.toStringAsFixed(2);
  }

  static String _statusLabelAr(String status) {
    switch (status) {
      case 'new':
        return 'جديدة';
      case 'diagnosing':
        return 'قيد الفحص';
      case 'repairing':
        return 'قيد الإصلاح';
      case 'waiting_parts':
        return 'في انتظار قطع';
      case 'ready':
        return 'جاهزة';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  static String _priorityLabelAr(String priority) {
    switch (priority) {
      case 'low':
        return 'منخفضة';
      case 'normal':
        return 'عادية';
      case 'high':
        return 'عالية';
      case 'urgent':
        return 'عاجلة';
      default:
        return priority;
    }
  }
}

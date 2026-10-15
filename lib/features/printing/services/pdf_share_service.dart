// lib/features/printing/services/pdf_share_service.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../invoices/data/models/invoice_model.dart';

class PdfShareService {
  // =====================================================
  // طباعة مباشرة
  // - لو الطابعة مش متاحة أو المنصة iOS → نستخدم المعاينة
  // =====================================================
  static Future<void> printPdf({
    required Uint8List bytes,
    required String jobName,
  }) async {
    try {
      // على الويب → معاينة مباشرة
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: jobName,
        );
        return;
      }

      // على الموبايل → نحاول نطبع
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: jobName,
      );
    } catch (e) {
      debugPrint('❌ printPdf error: $e');
      // fallback: نفتح الملف نفسه
      await openPdfFromBytes(bytes: bytes, filename: '$jobName.pdf');
    }
  }

  // =====================================================
  // معاينة
  // =====================================================
  static Future<void> previewPdf({
    required Uint8List bytes,
    required String jobName,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: jobName,
      );
    } catch (e) {
      debugPrint('❌ previewPdf error: $e');
      await openPdfFromBytes(bytes: bytes, filename: '$jobName.pdf');
    }
  }

  // =====================================================
  // ⭐ فتح PDF من bytes باستخدام open_file (يشتغل على Android + iOS)
  // =====================================================
  static Future<void> openPdfFromBytes({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      // على الويب → مفيش open_file
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: filename,
        );
        return;
      }

      // نحفظ الملف في مجلد مؤقت
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      // نفتحه بالتطبيق الافتراضي
      final result = await OpenFile.open(file.path);

      if (result.type != ResultType.done) {
        debugPrint('⚠️ open_file failed: ${result.message}');
        // fallback: نشارك الملف
        await sharePdf(
          bytes: bytes,
          filename: filename,
        );
      }
    } catch (e) {
      debugPrint('❌ openPdfFromBytes error: $e');
    }
  }

  // =====================================================
  // مشاركة عامة (واتساب / إيميل / أي تطبيق)
  // =====================================================
  static Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
    String? text,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      final result = await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: filename,
          ),
        ],
        subject: filename,
        text: text,
      );

      if (result.status == ShareResultStatus.dismissed) {
        debugPrint('ℹ️ User dismissed share');
      }
    } catch (e) {
      debugPrint('❌ sharePdf error: $e');
    }
  }

  // =====================================================
  // مشاركة على واتساب (مع ملف)
  // =====================================================
  static Future<void> shareViaWhatsApp({
    required Uint8List bytes,
    required String filename,
    required String phone,
    required String invoiceNumber,
    required String total,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      final message = 'بيان رقم: $invoiceNumber\n'
          'الإجمالي: $total\n\n'
          'مرفق البيان 👇';

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: filename,
          ),
        ],
        subject: 'بيان $invoiceNumber',
        text: message,
      );
    } catch (e) {
      debugPrint('❌ shareViaWhatsApp error: $e');
    }
  }

  // =====================================================
  // إرسال نص على واتساب (بدون ملف)
  // =====================================================
  static Future<void> sendWhatsAppText({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('مش قادر أفتح واتساب');
    }
  }

  // =====================================================
  // إرسال إيميل
  // =====================================================
  static Future<void> shareViaEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    final url = Uri(
      scheme: 'mailto',
      path: to,
      query: 'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('مش قادر أفتح تطبيق الإيميل');
    }
  }

  // =====================================================
  // حفظ الملف في Documents
  // =====================================================
  static Future<String> savePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // =====================================================
  // نص مشاركة البيان (واتساب / SMS)
  // =====================================================
  static String buildShareText(InvoiceModel invoice) {
    final buffer = StringBuffer();
    buffer.writeln('🌟 *بيان جديد* 🌟');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 رقم البيان: ${invoice.invoiceNumber}');
    buffer.writeln('📅 التاريخ: ${_fmtDate(invoice.invoiceDate)}');
    if (invoice.customerName != null) {
      buffer.writeln('👤 العميل: ${invoice.customerName}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('📦 البنود:');
    for (final item in invoice.items) {
      buffer.writeln(
        '  • ${item.displayName} × ${item.quantity} = '
        '${item.quantity * item.unitPrice} ج.م',
      );
    }
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 الإجمالي: ${invoice.total} ج.م');
    if (invoice.paidAmount > 0) {
      buffer.writeln('✅ المدفوع: ${invoice.paidAmount} ج.م');
    }
    if (invoice.dueAmount > 0) {
      buffer.writeln('⚠️ المتبقي: ${invoice.dueAmount} ج.م');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('شكراً لتعاملكم معنا 🌟');
    return buffer.toString();
  }

  // =====================================================
  // Helper
  // =====================================================
  static String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}

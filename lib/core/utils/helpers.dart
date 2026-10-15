// lib/core/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

class Helpers {
  // =====================================================
  // Supabase shortcuts
  // =====================================================
  static SupabaseClient get supabase => Supabase.instance.client;

  static User? get currentUser => supabase.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  // =====================================================
  // التاريخ والوقت
  // =====================================================

  /// تاريخ اليوم بصيغة yyyy-MM-dd
  static String today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// تنسيق التاريخ من DateTime
  static String formatDate(DateTime? date, {String? format}) {
    if (date == null) return '-';
    return DateFormat(format ?? AppConstants.displayDateFormat).format(date);
  }

  /// تنسيق الوقت من DateTime
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('hh:mm a', 'ar').format(date);
  }

  /// تنسيق التاريخ والوقت
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat(AppConstants.displayDateTimeFormat).format(date);
  }

  /// تحويل نص لتاريخ
  static DateTime? parseDate(String? date) {
    if (date == null || date.isEmpty) return null;
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  /// الفرق بين تاريخين بالأيام
  static int daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays;
  }

  /// هل التاريخ النهاردة؟
  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// الوقت الحالي بصيغة "منذ X"
  static String timeAgo(DateTime? date) {
    if (date == null) return '-';
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    if (diff.inDays < 365) return 'منذ ${(diff.inDays / 30).floor()} شهر';
    return 'منذ ${(diff.inDays / 365).floor()} سنة';
  }

  /// اسم الشهر بالعربي
  static String monthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  /// اسم اليوم بالعربي
  static String dayName(int weekday) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  // =====================================================
  // الأرقام
  // =====================================================

  /// تنسيق رقم بفواصل
  static String formatNumber(num? value, {int decimals = 0}) {
    if (value == null) return '0';
    final decimalPart = decimals > 0 ? '.${'0' * decimals}' : '';
    final formatter = NumberFormat('#,##0$decimalPart');
    return formatter.format(value);
  }

  /// تنسيق السعر
  static String formatCurrency(num? amount, {int decimals = 2}) {
    if (amount == null) return '0.00 ${AppConstants.currency}';
    return '${formatNumber(amount, decimals: decimals)} ${AppConstants.currency}';
  }

  /// تنسيق دقايق لصيغة مفهومة (2س 30د)
  static String formatMinutes(int? minutes) {
    if (minutes == null || minutes <= 0) return '0 دقيقة';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m دقيقة';
    if (m == 0) return '$h ساعة';
    return '$h ساعة و $m دقيقة';
  }

  /// تحويل نسبة لـ %
  static String formatPercent(num? value) {
    if (value == null) return '0%';
    return '${value.toStringAsFixed(1)}%';
  }

  // =====================================================
  // النصوص
  // =====================================================

  /// اختصار النص الطويل
  static String truncate(String? text, int maxLength) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// أول حرف من كل كلمة (للأفاتار)
  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// التحقق من الإيميل
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  /// التحقق من رقم الموبايل المصري
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final regex = RegExp(r'^01[0-2,5]\d{8}$');
    return regex.hasMatch(phone);
  }

  // =====================================================
  // الرسائل (Snackbar & Dialog)
  // =====================================================

  /// رسالة نجاح
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, color: Colors.green);
  }

  /// رسالة خطأ
  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, color: Colors.red);
  }

  /// رسالة تحذير
  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, color: Colors.orange);
  }

  /// رسالة عادية
  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, color: Colors.blue);
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color color,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dialog تأكيد
  static Future<bool> confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Dialog انتظار
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(message ?? 'جارٍ التحميل...')),
            ],
          ),
        ),
      ),
    );
  }

  /// إغلاق Dialog الانتظار
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  // =====================================================
  // التحقق من الاتصال
  // =====================================================

  /// هل المستخدم أدمن؟
  static bool isAdmin(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    final role = profile['roles'];
    if (role is Map) return role['code'] == AppConstants.roleAdmin;
    return false;
  }

  /// الحصول على كود الدور من البروفايل
  static String? getRoleCode(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final role = profile['roles'];
    if (role is Map) return role['code'] as String?;
    return null;
  }

  /// هل المستخدم عنده دور معين؟
  static bool hasRole(Map<String, dynamic>? profile, String roleCode) {
    return getRoleCode(profile) == roleCode;
  }

  /// هل المستخدم أدمن أو مدير؟
  static bool isAdminOrManager(Map<String, dynamic>? profile) {
    final role = getRoleCode(profile);
    return role == AppConstants.roleAdmin || role == AppConstants.roleManager;
  }

  // =====================================================
  // Generic
  // =====================================================

  /// تحويل String لـ double بأمان
  static double parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// تحويل String لـ int بأمان
  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// إخفاء تفاصيل حساسة
  static String maskPhone(String? phone) {
    if (phone == null || phone.length < 4) return phone ?? '';
    return '${phone.substring(0, 4)}****${phone.substring(phone.length - 2)}';
  }
}

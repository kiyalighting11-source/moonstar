// lib/core/utils/attendance_helpers.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import 'location_service.dart';

class AttendanceHelpers {
  // =====================================================
  // التحقق من الجهاز والموقع
  // =====================================================

  /// هل الجهاز مسجل ومطابق؟
  static bool isDeviceMatch({
    required String? savedDeviceId,
    required String currentDeviceId,
  }) {
    if (savedDeviceId == null || savedDeviceId.isEmpty) return false;
    return savedDeviceId == currentDeviceId;
  }

  /// هل الموقع جوه النطاق؟
  static bool isLocationWithinRadius({
    required double? companyLat,
    required double? companyLng,
    required double currentLat,
    required double currentLng,
    required int radiusMeters,
  }) {
    if (companyLat == null || companyLng == null) {
      return false; // الإحداثيات مش مسجلة
    }

    return LocationService.isWithinRadius(
      currentLat: currentLat,
      currentLng: currentLng,
      targetLat: companyLat,
      targetLng: companyLng,
      radiusMeters: radiusMeters.toDouble(),
    );
  }

  /// حساب المسافة من الشركة
  static double distanceFromCompany({
    required double? companyLat,
    required double? companyLng,
    required double currentLat,
    required double currentLng,
  }) {
    if (companyLat == null || companyLng == null) return -1;

    return LocationService.distanceBetween(
      lat1: currentLat,
      lng1: currentLng,
      lat2: companyLat,
      lng2: companyLng,
    );
  }

  // =====================================================
  // حساب الحالة والأوقات
  // =====================================================

  /// هل الوقت ده إجازة أسبوعية؟
  static bool isWeekend(DateTime date, int weekendDay) {
    // DateTime.weekday: 1=Monday..7=Sunday
    // settings.weekend_day: 0=Sunday..6=Saturday
    final day = date.weekday % 7;
    return day == weekendDay;
  }

  /// حساب دقايق التأخير
  /// - شفت 13:30، التسامح 15 دقيقة → لحد 13:45 مفيش تأخير
  /// - بعد كده: الفرق من 13:30 (مش من 13:45)
  static int calculateLateMinutes({
    required DateTime checkIn,
    required String shiftStart,
    required int graceMinutes,
  }) {
    final shiftStartTime = _parseTime(shiftStart);
    final checkInTime = TimeOfDay.fromDateTime(checkIn);

    final diff = _timeOfDayDiffInMinutes(shiftStartTime, checkInTime);
    if (diff <= 0) return 0;

    // لو في نطاق التسامح → مفيش تأخير
    if (diff <= graceMinutes) return 0;

    // بعد التسامح → الفرق كامل من بداية الشيفت
    return diff;
  }

  /// حساب دقايق الخروج المبكر
  static int calculateEarlyLeaveMinutes({
    required DateTime checkOut,
    required String shiftEnd,
  }) {
    final shiftEndTime = _parseTime(shiftEnd);
    final checkOutTime = TimeOfDay.fromDateTime(checkOut);

    final diff = _timeOfDayDiffInMinutes(checkOutTime, shiftEndTime);
    return diff > 0 ? diff : 0;
  }

  /// حساب الدقايق الفعلية للعمل
  static int calculateWorkedMinutes({
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    final diff = checkOut.difference(checkIn).inMinutes;
    return diff > 0 ? diff : 0;
  }

  /// هل الموظف "متأخر جداً"؟
  /// لو دخل بعد وقت الغياب (14:30)
  static bool isVeryLate({
    required DateTime checkIn,
    required String absenceMarkTime,
  }) {
    final absenceTime = _parseTime(absenceMarkTime);
    final checkInTime = TimeOfDay.fromDateTime(checkIn);
    return _timeOfDayDiffInMinutes(absenceTime, checkInTime) > 0;
  }

  // =====================================================
  // Helper
  // =====================================================

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 0, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  /// فرق بين وقتين بالدقايق (positive لو to > from)
  static int _timeOfDayDiffInMinutes(TimeOfDay from, TimeOfDay to) {
    final fromM = from.hour * 60 + from.minute;
    final toM = to.hour * 60 + to.minute;
    return toM - fromM;
  }

  // =====================================================
  // Formatting
  // =====================================================

  static String formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a', 'ar').format(dt);
  }

  static String formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  static String formatDateFull(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('EEEE، dd MMM yyyy', 'ar').format(dt);
  }

  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0 دقيقة';
    if (minutes < 60) return '$minutes دقيقة';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h ساعة';
    return '$h س و $m د';
  }

  // =====================================================
  // Colors & Labels
  // =====================================================

  static Color statusColor(String status) {
    final hex = AppConstants.attendanceStatusColors[status];
    if (hex == null) return Colors.grey;
    return Color(hex);
  }

  static String statusLabel(String status) {
    return AppConstants.attendanceStatusAr[status] ?? status;
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'very_late':
        return Icons.warning_amber;
      case 'absent':
        return Icons.cancel;
      case 'weekend':
        return Icons.weekend;
      default:
        return Icons.info;
    }
  }
}

// lib/features/attendance/data/repositories/attendance_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/attendance_model.dart';
import '../models/attendance_stats_model.dart';

class AttendanceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _selectWithEmployee =
      '*, employees!employee_id (full_name, employee_code, job_title)';

  // =====================================================
  // QUERIES
  // =====================================================

  Future<List<AttendanceModel>> getEmployeeAttendance({
    required String employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) async {
    var query = _supabase
        .from(AppConstants.attendanceTable)
        .select(_selectWithEmployee)
        .eq('employee_id', employeeId);

    if (fromDate != null) {
      query = query.gte('date', _fmt(fromDate));
    }
    if (toDate != null) {
      query = query.lte('date', _fmt(toDate));
    }

    final data = await query.order('date', ascending: false).limit(limit);

    return (data as List).map((e) => AttendanceModel.fromJson(e)).toList();
  }

  Future<List<AttendanceModel>> getDailyAttendance(DateTime date) async {
    final data = await _supabase
        .from(AppConstants.attendanceTable)
        .select(_selectWithEmployee)
        .eq('date', _fmt(date))
        .order('check_in', ascending: true, nullsFirst: false);

    return (data as List).map((e) => AttendanceModel.fromJson(e)).toList();
  }

  Future<List<AttendanceModel>> getTodayAttendance() {
    return getDailyAttendance(DateTime.now());
  }

  Future<AttendanceModel?> getEmployeeAttendanceForDate({
    required String employeeId,
    required DateTime date,
  }) async {
    final data = await _supabase
        .from(AppConstants.attendanceTable)
        .select(_selectWithEmployee)
        .eq('employee_id', employeeId)
        .eq('date', _fmt(date))
        .maybeSingle();

    if (data == null) return null;
    return AttendanceModel.fromJson(data);
  }

  Future<List<AttendanceModel>> getAttendanceRange({
    required DateTime fromDate,
    required DateTime toDate,
    String? employeeId,
    int? limit,
  }) async {
    var query = _supabase
        .from(AppConstants.attendanceTable)
        .select(_selectWithEmployee)
        .gte('date', _fmt(fromDate))
        .lte('date', _fmt(toDate));

    if (employeeId != null) {
      query = query.eq('employee_id', employeeId);
    }

    final data = await query.order('date', ascending: false);

    final list =
        (data as List).map((e) => AttendanceModel.fromJson(e)).toList();
    return limit != null && list.length > limit ? list.sublist(0, limit) : list;
  }

  // =====================================================
  // STATS
  // =====================================================

  Future<AttendanceStatsModel> getTodayStats() async {
    final today = DateTime.now();
    final daily = await getDailyAttendance(today);
    final employeesCount = await _getActiveEmployeesCount();

    int present = 0;
    int late = 0;
    int veryLate = 0;
    int absent = 0;
    int lateMinutes = 0;

    for (final a in daily) {
      switch (a.status) {
        case 'present':
          present++;
          break;
        case 'late':
          late++;
          lateMinutes += a.lateMinutes;
          break;
        case 'very_late':
          veryLate++;
          lateMinutes += a.lateMinutes;
          break;
        case 'absent':
          absent++;
          break;
      }
    }

    final notCheckedIn = employeesCount - daily.length;

    return AttendanceStatsModel(
      totalEmployees: employeesCount,
      presentToday: present,
      lateToday: late,
      veryLateToday: veryLate,
      absentToday: absent,
      notCheckedInYet: notCheckedIn < 0 ? 0 : notCheckedIn,
      totalLateMinutesToday: lateMinutes,
      attendanceRate: employeesCount == 0
          ? 0
          : ((present + late + veryLate) / employeesCount) * 100,
    );
  }

  /// ⭐ إحصائيات موظف في فترة (للرواتب) — مع تحسين للتعامل مع السجلات المفتوحة
  Future<Map<String, dynamic>> getEmployeePeriodStats({
    required String employeeId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final data = await _supabase
        .from(AppConstants.attendanceTable)
        .select(
            'status, late_minutes, early_leave_minutes, worked_minutes, check_in, check_out')
        .eq('employee_id', employeeId)
        .gte('date', _fmt(fromDate))
        .lte('date', _fmt(toDate));

    int presentDays = 0;
    int lateDays = 0;
    int absentDays = 0;
    int veryLateDays = 0;
    int weekendDays = 0;
    int totalLateMinutes = 0;
    int totalWorkedMinutes = 0;
    int openRecords = 0; // ⭐ سجلات مسجلة حضور بس لسه مسجلتش انصراف

    for (final row in (data as List)) {
      final status = row['status'] as String? ?? '';
      final late = (row['late_minutes'] as num?)?.toInt() ?? 0;
      final worked = (row['worked_minutes'] as num?)?.toInt() ?? 0;
      final checkIn = row['check_in'];
      final checkOut = row['check_out'];

      // ⭐ لو فيه check_in بس مفيش check_out → سجل مفتوح
      if (checkIn != null && checkOut == null) {
        openRecords++;
      }

      switch (status) {
        case 'present':
          presentDays++;
          break;
        case 'late':
          presentDays++;
          lateDays++;
          totalLateMinutes += late;
          break;
        case 'very_late':
          presentDays++;
          veryLateDays++;
          totalLateMinutes += late;
          break;
        case 'absent':
          absentDays++;
          break;
        case 'weekend':
          weekendDays++;
          break;
      }

      totalWorkedMinutes += worked;
    }

    return {
      'present_days': presentDays,
      'late_days': lateDays,
      'very_late_days': veryLateDays,
      'absent_days': absentDays,
      'weekend_days': weekendDays,
      'total_late_minutes': totalLateMinutes,
      'total_worked_minutes': totalWorkedMinutes,
      'total_records': (data as List).length,
      'open_records': openRecords, // ⭐ جديد
    };
  }

  // =====================================================
  // CHECK IN / CHECK OUT
  // =====================================================

  Future<AttendanceModel> checkIn({
    required String employeeId,
    required String deviceId,
    required double lat,
    required double lng,
    required double distanceFromCompany,
  }) async {
    final today = DateTime.now();
    final payload = {
      'employee_id': employeeId,
      'date': _fmt(today),
      'check_in': DateTime.now().toIso8601String(),
      'device_id_used': deviceId,
      'location_lat': lat,
      'location_lng': lng,
      'distance_from_company': distanceFromCompany,
      'registered_by': _supabase.auth.currentUser?.id,
    };

    final data = await _supabase
        .from(AppConstants.attendanceTable)
        .insert(payload)
        .select(_selectWithEmployee)
        .single();

    return AttendanceModel.fromJson(data);
  }

  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required String deviceId,
    required double lat,
    required double lng,
    required double distanceFromCompany,
  }) async {
    final data = await _supabase
        .from(AppConstants.attendanceTable)
        .update({
          'check_out': DateTime.now().toIso8601String(),
          'device_id_used': deviceId,
          'location_lat': lat,
          'location_lng': lng,
          'distance_from_company': distanceFromCompany,
        })
        .eq('id', attendanceId)
        .select(_selectWithEmployee)
        .single();

    return AttendanceModel.fromJson(data);
  }

  Future<AttendanceModel> selfCheckIn({
    required String employeeId,
    required String deviceId,
    required double lat,
    required double lng,
    required double distance,
  }) {
    return checkIn(
      employeeId: employeeId,
      deviceId: deviceId,
      lat: lat,
      lng: lng,
      distanceFromCompany: distance,
    );
  }

  // =====================================================
  // ADMIN ACTIONS
  // =====================================================

  /// ⭐ تسجيل حضور يدوي — مع حماية من التكرار (upsert)
  Future<AttendanceModel> manualCheckIn({
    required String employeeId,
    DateTime? checkInTime,
    String? note,
  }) async {
    final now = checkInTime ?? DateTime.now();

    // ⭐ نتأكد مفيش سجل موجود بالفعل لنفس الموظف في نفس اليوم
    final existing = await getEmployeeAttendanceForDate(
      employeeId: employeeId,
      date: now,
    );

    if (existing != null) {
      // لو موجود، نعمل update بدل insert
      final data = await _supabase
          .from(AppConstants.attendanceTable)
          .update({
            'check_in': now.toIso8601String(),
            'note': note ?? 'تسجيل يدوي من الإدارة (تحديث)',
            'registered_by': _supabase.auth.currentUser?.id,
          })
          .eq('id', existing.id)
          .select(_selectWithEmployee)
          .single();

      return AttendanceModel.fromJson(data);
    }

    // لو مش موجود → insert جديد
    final payload = {
      'employee_id': employeeId,
      'date': _fmt(now),
      'check_in': now.toIso8601String(),
      'note': note ?? 'تسجيل يدوي من الإدارة',
      'registered_by': _supabase.auth.currentUser?.id,
    };

    final data = await _supabase
        .from(AppConstants.attendanceTable)
        .insert(payload)
        .select(_selectWithEmployee)
        .single();

    return AttendanceModel.fromJson(data);
  }

  Future<AttendanceModel> updateAttendance({
    required String id,
    DateTime? checkIn,
    DateTime? checkOut,
    String? status,
    String? note,
  }) async {
    final updates = <String, dynamic>{};
    if (checkIn != null) updates['check_in'] = checkIn.toIso8601String();
    if (checkOut != null) updates['check_out'] = checkOut.toIso8601String();
    if (status != null) updates['status'] = status;
    if (note != null) updates['note'] = note;
    updates['registered_by'] = _supabase.auth.currentUser?.id;

    final data = await _supabase
        .from(AppConstants.attendanceTable)
        .update(updates)
        .eq('id', id)
        .select(_selectWithEmployee)
        .single();

    return AttendanceModel.fromJson(data);
  }

  Future<void> deleteAttendance(String id) async {
    await _supabase.from(AppConstants.attendanceTable).delete().eq('id', id);
  }

  // =====================================================
  // HELPERS
  // =====================================================

  Future<int> _getActiveEmployeesCount() async {
    final data = await _supabase
        .from(AppConstants.employeesTable)
        .select('id, profiles!profile_id (roles!role_id (code))')
        .eq('is_active', true);

    int count = 0;
    for (final e in (data as List)) {
      final profile = e['profiles'];
      final role = profile is Map ? profile['roles'] : null;
      final code = role is Map ? role['code'] as String? : null;
      if (code != 'admin' && code != 'manager') count++;
    }
    return count;
  }

  static String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

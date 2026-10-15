// lib/features/attendance/providers/attendance_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/attendance_model.dart';
import '../data/models/attendance_stats_model.dart';
import '../data/repositories/attendance_repository.dart';

// =====================================================
// Repository Provider
// =====================================================
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

// =====================================================
// الفلاتر
// =====================================================
class AttendanceFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? employeeId;
  final String? status;

  const AttendanceFilter({
    this.fromDate,
    this.toDate,
    this.employeeId,
    this.status,
  });

  AttendanceFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? employeeId,
    String? status,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearEmployee = false,
    bool clearStatus = false,
  }) {
    return AttendanceFilter(
      fromDate: clearFrom ? null : (fromDate ?? this.fromDate),
      toDate: clearTo ? null : (toDate ?? this.toDate),
      employeeId: clearEmployee ? null : (employeeId ?? this.employeeId),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

final attendanceFilterProvider =
    StateProvider<AttendanceFilter>((ref) => const AttendanceFilter());

// =====================================================
// سجل حضور موظف (للموظف نفسه)
// =====================================================
final employeeAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceModel>, String>((ref, employeeId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getEmployeeAttendance(employeeId: employeeId, limit: 60);
});

// =====================================================
// حضور اليوم (للمدير/الأدمن)
// =====================================================
final todayAttendanceProvider =
    FutureProvider.autoDispose<List<AttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getTodayAttendance();
});

// =====================================================
// حضور يوم معين
// =====================================================
final dailyAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceModel>, DateTime>((ref, date) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getDailyAttendance(date);
});

// =====================================================
// إحصائيات اليوم
// =====================================================
final todayStatsProvider =
    FutureProvider.autoDispose<AttendanceStatsModel>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getTodayStats();
});

// =====================================================
// حضور موظف في يوم معين (لزرار Check in/out)
// =====================================================
final employeeTodayAttendanceProvider = FutureProvider.autoDispose
    .family<AttendanceModel?, String>((ref, employeeId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getEmployeeAttendanceForDate(
    employeeId: employeeId,
    date: DateTime.now(),
  );
});

// =====================================================
// سجل حضور نطاق تاريخ (للتقارير)
// =====================================================
final attendanceRangeProvider = FutureProvider.autoDispose
    .family<List<AttendanceModel>, AttendanceFilter>((ref, filter) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getAttendanceRange(
    fromDate:
        filter.fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
    toDate: filter.toDate ?? DateTime.now(),
    employeeId: filter.employeeId,
  );
});

// =====================================================
// Controller
// =====================================================
class AttendanceController extends StateNotifier<AsyncValue<void>> {
  AttendanceController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final AttendanceRepository _repo;
  final Ref _ref;

  /// الموظف يسجل حضور
  Future<AttendanceModel?> selfCheckIn({
    required String employeeId,
    required String deviceId,
    required double lat,
    required double lng,
    required double distance,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.selfCheckIn(
        employeeId: employeeId,
        deviceId: deviceId,
        lat: lat,
        lng: lng,
        distance: distance,
      );
      state = const AsyncValue.data(null);
      _refreshAll(employeeId);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// الموظف يسجل انصراف
  Future<AttendanceModel?> checkOut({
    required String attendanceId,
    required String employeeId,
    required String deviceId,
    required double lat,
    required double lng,
    required double distance,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.checkOut(
        attendanceId: attendanceId,
        deviceId: deviceId,
        lat: lat,
        lng: lng,
        distanceFromCompany: distance,
      );
      state = const AsyncValue.data(null);
      _refreshAll(employeeId);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// الأدمن يسجل يدوي
  Future<AttendanceModel?> manualCheckIn({
    required String employeeId,
    DateTime? checkInTime,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.manualCheckIn(
        employeeId: employeeId,
        checkInTime: checkInTime,
        note: note,
      );
      state = const AsyncValue.data(null);
      _refreshAll(employeeId);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// الأدمن يعدّل
  Future<bool> updateAttendance({
    required String id,
    required String employeeId,
    DateTime? checkIn,
    DateTime? checkOut,
    String? status,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateAttendance(
        id: id,
        checkIn: checkIn,
        checkOut: checkOut,
        status: status,
        note: note,
      );
      state = const AsyncValue.data(null);
      _refreshAll(employeeId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// حذف
  Future<bool> delete(String id, {String? employeeId}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAttendance(id);
      state = const AsyncValue.data(null);
      _refreshAll(employeeId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _refreshAll(String? employeeId) {
    _ref.invalidate(todayAttendanceProvider);
    _ref.invalidate(todayStatsProvider);
    if (employeeId != null) {
      _ref.invalidate(employeeAttendanceProvider(employeeId));
      _ref.invalidate(employeeTodayAttendanceProvider(employeeId));
    }
  }
}

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AsyncValue<void>>((ref) {
  return AttendanceController(ref.read(attendanceRepositoryProvider), ref);
});

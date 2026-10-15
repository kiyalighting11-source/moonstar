// lib/features/attendance/data/models/attendance_stats_model.dart

class AttendanceStatsModel {
  final int totalEmployees;
  final int presentToday;
  final int lateToday;
  final int veryLateToday;
  final int absentToday;
  final int notCheckedInYet;

  final int totalLateMinutesToday;
  final double attendanceRate; // 0..100

  AttendanceStatsModel({
    this.totalEmployees = 0,
    this.presentToday = 0,
    this.lateToday = 0,
    this.veryLateToday = 0,
    this.absentToday = 0,
    this.notCheckedInYet = 0,
    this.totalLateMinutesToday = 0,
    this.attendanceRate = 0,
  });

  factory AttendanceStatsModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatsModel(
      totalEmployees: _i(json['total_employees']),
      presentToday: _i(json['present_today']),
      lateToday: _i(json['late_today']),
      veryLateToday: _i(json['very_late_today']),
      absentToday: _i(json['absent_today']),
      notCheckedInYet: _i(json['not_checked_in_yet']),
      totalLateMinutesToday: _i(json['total_late_minutes_today']),
      attendanceRate: _d(json['attendance_rate']),
    );
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

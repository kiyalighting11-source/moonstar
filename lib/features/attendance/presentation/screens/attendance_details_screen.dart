// lib/features/attendance/presentation/screens/attendance_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../data/models/attendance_model.dart';
import '../../providers/attendance_provider.dart';

class AttendanceDetailsScreen extends ConsumerWidget {
  final String attendanceId;

  const AttendanceDetailsScreen({
    super.key,
    required this.attendanceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filter = AttendanceFilter();
    final rangeAsync = ref.watch(attendanceRangeProvider(filter));
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'تفاصيل الحضور',
      ),
      body: rangeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ),
        data: (list) {
          final attendance =
              list.where((a) => a.id == attendanceId).firstOrNull;
          if (attendance == null) {
            return Center(
              child: Text(
                'السجل غير موجود',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            );
          }
          return _buildContent(context, ref, attendance, isDark);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AttendanceModel a,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(attendanceRangeProvider(const AttendanceFilter()));
        await ref
            .read(attendanceRangeProvider(const AttendanceFilter()).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, a, isDark),
          const SizedBox(height: 16),
          _section(context, isDark, 'الأوقات', [
            _row(
              context,
              Icons.login,
              'الحضور',
              AttendanceHelpers.formatTime(a.checkIn),
              color: a.hasCheckedIn ? AppTheme.successColor : null,
            ),
            _row(
              context,
              Icons.logout,
              'الانصراف',
              AttendanceHelpers.formatTime(a.checkOut),
              color: a.hasCheckedOut ? AppTheme.infoColor : null,
            ),
            _row(
              context,
              Icons.timer,
              'ساعات العمل',
              AttendanceHelpers.formatMinutes(a.workedMinutes),
              color: AppTheme.primaryColor,
            ),
          ]),
          const SizedBox(height: 12),
          if (a.lateMinutes > 0 || a.earlyLeaveMinutes > 0) ...[
            _section(context, isDark, 'التأخير والخروج', [
              if (a.lateMinutes > 0)
                _row(
                  context,
                  Icons.access_time,
                  'التأخير',
                  AttendanceHelpers.formatMinutes(a.lateMinutes),
                  color: AppTheme.warningColor,
                ),
              if (a.earlyLeaveMinutes > 0)
                _row(
                  context,
                  Icons.exit_to_app,
                  'خروج مبكر',
                  AttendanceHelpers.formatMinutes(a.earlyLeaveMinutes),
                  color: AppTheme.warningColor,
                ),
            ]),
            const SizedBox(height: 12),
          ],
          if (a.deviceIdUsed != null ||
              (a.locationLat != null && a.locationLng != null) ||
              a.distanceFromCompany != null) ...[
            _section(context, isDark, 'التحقق', [
              if (a.deviceIdUsed != null && a.deviceIdUsed!.isNotEmpty)
                _row(
                  context,
                  Icons.phone_android,
                  'الجهاز',
                  _shortDeviceId(a.deviceIdUsed!),
                ),
              if (a.locationLat != null && a.locationLng != null)
                _row(
                  context,
                  Icons.my_location,
                  'الموقع',
                  '${a.locationLat!.toStringAsFixed(5)}, '
                      '${a.locationLng!.toStringAsFixed(5)}',
                ),
              if (a.distanceFromCompany != null)
                _row(
                  context,
                  Icons.straighten,
                  'المسافة',
                  '${a.distanceFromCompany!.toStringAsFixed(0)} متر',
                ),
            ]),
            const SizedBox(height: 12),
          ],
          if (a.note != null && a.note!.isNotEmpty) ...[
            _section(context, isDark, 'ملاحظات', [
              Text(
                a.note!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textColor(context),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],
          if (a.createdAt != null)
            _section(context, isDark, 'معلومات السجل', [
              _row(
                context,
                Icons.schedule,
                'وقت الإنشاء',
                AttendanceHelpers.formatTime(a.createdAt),
              ),
              if (a.updatedAt != null && a.updatedAt != a.createdAt)
                _row(
                  context,
                  Icons.update,
                  'آخر تعديل',
                  AttendanceHelpers.formatTime(a.updatedAt),
                ),
            ]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AttendanceModel a,
    bool isDark,
  ) {
    final color = AttendanceHelpers.statusColor(a.status);
    final icon = AttendanceHelpers.statusIcon(a.status);
    final label = AttendanceHelpers.statusLabel(a.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 50),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (a.employeeName != null) ...[
            const SizedBox(height: 10),
            Text(
              a.employeeName!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            if (a.employeeCode != null)
              Text(
                a.employeeCode!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151A23) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AttendanceHelpers.formatDateFull(a.date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    bool isDark,
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondaryColor(context),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDeviceId(String deviceId) {
    if (deviceId.length <= 16) return deviceId;
    return '${deviceId.substring(0, 8)}...'
        '${deviceId.substring(deviceId.length - 6)}';
  }
}

// lib/features/attendance/presentation/widgets/attendance_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_helpers.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/attendance_model.dart';
import 'attendance_status_badge.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  final bool showEmployee;
  final VoidCallback? onTap;

  const AttendanceCard({
    super.key,
    required this.attendance,
    this.showEmployee = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final statusColor = AttendanceHelpers.statusColor(attendance.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== الصف الأول ====================
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: showEmployee
                      ? Text(
                          Helpers.initials(attendance.employeeName ?? '?'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        )
                      : Icon(
                          AttendanceHelpers.statusIcon(attendance.status),
                          color: statusColor,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),

                // الاسم + التاريخ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showEmployee && attendance.employeeName != null) ...[
                        Text(
                          attendance.employeeName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AttendanceHelpers.formatDate(attendance.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                          if (attendance.employeeCode != null &&
                              showEmployee) ...[
                            const SizedBox(width: 8),
                            Text(
                              attendance.employeeCode!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge الحالة
                AttendanceStatusBadge(status: attendance.status),
              ],
            ),

            // ==================== الأوقات ====================
            if (attendance.hasCheckedIn) ...[
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.dividerColor,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _timeItem(
                      context,
                      icon: Icons.login,
                      label: 'حضور',
                      value: AttendanceHelpers.formatTime(attendance.checkIn),
                      color: AppTheme.successColor,
                    ),
                  ),
                  if (attendance.hasCheckedOut)
                    Expanded(
                      child: _timeItem(
                        context,
                        icon: Icons.logout,
                        label: 'انصراف',
                        value: AttendanceHelpers.formatTime(
                          attendance.checkOut,
                        ),
                        color: AppTheme.infoColor,
                      ),
                    )
                  else
                    Expanded(
                      child: _timeItem(
                        context,
                        icon: Icons.hourglass_empty,
                        label: 'انصراف',
                        value: 'لسه',
                        color: AppTheme.warningColor,
                      ),
                    ),
                  if (attendance.workedMinutes > 0)
                    Expanded(
                      child: _timeItem(
                        context,
                        icon: Icons.timer,
                        label: 'ساعات',
                        value: AttendanceHelpers.formatMinutes(
                          attendance.workedMinutes,
                        ),
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ],

            // ==================== التأخير ====================
            if (attendance.lateMinutes > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attendance.lateLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================== الخروج المبكر ====================
            if (attendance.earlyLeaveMinutes > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.exit_to_app,
                      size: 12,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attendance.earlyLeaveLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

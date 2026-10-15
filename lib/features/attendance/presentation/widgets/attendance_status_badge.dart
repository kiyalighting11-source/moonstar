// lib/features/attendance/presentation/widgets/attendance_status_badge.dart

import 'package:flutter/material.dart';

import '../../../../core/utils/attendance_helpers.dart';

class AttendanceStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const AttendanceStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final color = AttendanceHelpers.statusColor(status);
    final label = AttendanceHelpers.statusLabel(status);
    final icon = AttendanceHelpers.statusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

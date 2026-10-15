// lib/features/maintenance/presentation/widgets/maintenance_status_badge.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class MaintenanceStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const MaintenanceStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final label = _statusLabel;
    final icon = _statusIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case 'new':
        return AppTheme.infoColor;
      case 'diagnosing':
        return const Color(0xFF7E57C2);
      case 'repairing':
        return const Color(0xFFFB8C00);
      case 'waiting_parts':
        return const Color(0xFFE53935);
      case 'ready':
        return const Color(0xFF00ACC1);
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get _statusLabel {
    return AppConstants.maintStatusAr[status] ?? status;
  }

  IconData get _statusIcon {
    switch (status) {
      case 'new':
        return Icons.fiber_new;
      case 'diagnosing':
        return Icons.search;
      case 'repairing':
        return Icons.build;
      case 'waiting_parts':
        return Icons.hourglass_empty;
      case 'ready':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

// =====================================================
// Priority Badge
// =====================================================
class MaintenancePriorityBadge extends StatelessWidget {
  final String priority;
  final double fontSize;

  const MaintenancePriorityBadge({
    super.key,
    required this.priority,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor;
    final label = _priorityLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color get _priorityColor {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'normal':
        return AppTheme.infoColor;
      case 'high':
        return const Color(0xFFFB8C00);
      case 'urgent':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get _priorityLabel {
    return AppConstants.priorityAr[priority] ?? priority;
  }
}

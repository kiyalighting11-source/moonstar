// lib/features/admin/presentation/widgets/device_employee_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../employees/data/models/employee_model.dart';

class DeviceEmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback? onManage;
  final VoidCallback? onUnlink;

  const DeviceEmployeeCard({
    super.key,
    required this.employee,
    this.onManage,
    this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final hasDevice = employee.hasRegisteredDevice;
    final color = hasDevice ? AppTheme.successColor : AppTheme.warningColor;
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ⭐ خلفية حسب الوضع
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // أفاتار
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  Helpers.initials(employee.fullName),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // الاسم والكود
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: 12,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          employee.employeeCode,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                        if (employee.jobTitle != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              employee.jobTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Badge الحالة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasDevice ? Icons.verified_user : Icons.warning_amber,
                      size: 12,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasDevice ? 'مسجل' : 'مش مسجل',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ===== Device ID =====
          if (hasDevice) ...[
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
                Icon(
                  Icons.phone_android,
                  size: 14,
                  color: AppTheme.textSecondaryColor(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _shortDeviceId(employee.deviceId!),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (employee.deviceRegisteredAt != null)
                  Text(
                    Helpers.formatDate(employee.deviceRegisteredAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
              ],
            ),
          ],

          // ===== الأزرار =====
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManage,
                  icon: Icon(
                    hasDevice ? Icons.refresh : Icons.add_circle_outline,
                    size: 16,
                  ),
                  label: Text(
                    hasDevice ? 'تغيير الجهاز' : 'تسجيل جهاز',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (hasDevice && onUnlink != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUnlink,
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text(
                      'إلغاء الربط',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _shortDeviceId(String deviceId) {
    if (deviceId.length <= 20) return deviceId;
    return '${deviceId.substring(0, 10)}...'
        '${deviceId.substring(deviceId.length - 6)}';
  }
}

// lib/features/admin/presentation/widgets/quick_actions.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class QuickActions extends StatelessWidget {
  final bool isEmployee;

  const QuickActions({
    super.key,
    this.isEmployee = false,
  });

  @override
  Widget build(BuildContext context) {
    final actions = isEmployee ? _employeeActions : _adminActions;
    final isDark = AppTheme.isDark(context);

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final a = actions[index];
          return InkWell(
            onTap: () => context.go(a.route),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151A23) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? a.color.withValues(alpha: 0.3)
                      : a.color.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, color: a.color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1A1D24),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // للموظف
  // =====================================================
  static final List<_Action> _employeeActions = [
    _Action(
      label: 'تسجيل حضوري',
      icon: Icons.fingerprint,
      color: AppTheme.successColor,
      route: AppConstants.routeAttendanceCheckIn,
    ),
    _Action(
      label: 'سلفي',
      icon: Icons.money_off,
      color: AppTheme.warningColor,
      route: AppConstants.routeMyAdvances,
    ),
    _Action(
      label: 'رواتبي',
      icon: Icons.payments,
      color: AppTheme.primaryColor,
      route: AppConstants.routeMyPayrolls,
    ),
    _Action(
      label: 'سجل حضوري',
      icon: Icons.history,
      color: AppTheme.infoColor,
      route: AppConstants.routeMyAttendance,
    ),
  ];

  // =====================================================
  // للأدمن/المدير
  // =====================================================
  static final List<_Action> _adminActions = [
    _Action(
      label: 'إدارة الأجهزة',
      icon: Icons.phone_android,
      color: AppTheme.accentColor,
      route: AppConstants.routeDevicesManagement,
    ),
    _Action(
      label: 'بيان جديد',
      icon: Icons.receipt_long,
      color: AppTheme.successColor,
      route: AppConstants.routeAddInvoice,
    ),
    _Action(
      label: 'صيانة جديدة',
      icon: Icons.build_circle,
      color: AppTheme.errorColor,
      route: AppConstants.routeAddMaintenance,
    ),
    _Action(
      label: 'التقارير',
      icon: Icons.bar_chart,
      color: AppTheme.accentColor,
      route: AppConstants.routeReports,
    ),
    _Action(
      label: 'منتج جديد',
      icon: Icons.add_box,
      color: AppTheme.primaryColor,
      route: '/products/add',
    ),
    _Action(
      label: 'عميل جديد',
      icon: Icons.person_add,
      color: AppTheme.infoColor,
      route: '/customers/add',
    ),
    _Action(
      label: 'مخزن جديد',
      icon: Icons.warehouse,
      color: AppTheme.accentColor,
      route: '/warehouses/add',
    ),
    _Action(
      label: 'سلفة جديدة',
      icon: Icons.money_off,
      color: AppTheme.errorColor,
      route: AppConstants.routeAddAdvance,
    ),
    _Action(
      label: 'كشف راتب',
      icon: Icons.payments,
      color: AppTheme.successColor,
      route: '/payrolls/generate',
    ),
    _Action(
      label: 'حضور اليوم',
      icon: Icons.access_time,
      color: AppTheme.primaryColor,
      route: AppConstants.routeAttendance,
    ),
  ];
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  _Action({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}

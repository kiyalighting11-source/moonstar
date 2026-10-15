// lib/features/home/presentation/widgets/module_menu.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class ModuleMenu extends StatelessWidget {
  final String roleCode;

  const ModuleMenu({super.key, required this.roleCode});

  List<_MenuItem> _getMenuItems() {
    switch (roleCode) {
      case AppConstants.roleAdmin:
        return _adminMenu;
      case AppConstants.roleManager:
        return _managerMenu;
      case AppConstants.roleAccountant:
        return _accountantMenu;
      case AppConstants.roleStorekeeper:
        return _storekeeperMenu;
      case AppConstants.roleCashier:
        return _cashierMenu;
      case AppConstants.roleTechnician:
        return _technicianMenu;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getMenuItems();

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا توجد صلاحيات متاحة لهذا الدور',
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MenuTile(item: item);
      },
    );
  }

  // =====================================================
  // قوائم الأدوار
  // =====================================================

  // الأدمن — كل حاجة
  static const List<_MenuItem> _adminMenu = [
    _MenuItem('الموظفين', Icons.people, AppConstants.routeEmployees,
        AppTheme.infoColor),
    _MenuItem(
        'الأجهزة', Icons.phone_android, '/admin/devices', AppTheme.accentColor),
    _MenuItem('الحضور', Icons.access_time, AppConstants.routeAttendance,
        AppTheme.successColor),
    _MenuItem('الرواتب', Icons.payments, AppConstants.routePayrolls,
        AppTheme.primaryColor),
    _MenuItem('السلف', Icons.money_off, AppConstants.routeAdvances,
        AppTheme.errorColor),
    _MenuItem('المنتجات', Icons.inventory_2, AppConstants.routeProducts,
        AppTheme.accentColor),
    _MenuItem('المخازن', Icons.warehouse, AppConstants.routeWarehouses,
        AppTheme.infoColor),
    _MenuItem('المخزون', Icons.inventory, AppConstants.routeStock,
        AppTheme.successColor),
    _MenuItem('العملاء', Icons.people_alt, AppConstants.routeCustomers,
        AppTheme.primaryColor),
    _MenuItem('الفواتير', Icons.receipt_long, AppConstants.routeInvoices,
        AppTheme.accentColor),
    _MenuItem('الصيانة', Icons.build, AppConstants.routeMaintenance,
        AppTheme.errorColor),
    _MenuItem('التقارير', Icons.bar_chart, AppConstants.routeReports,
        AppTheme.infoColor),
    _MenuItem('الإعدادات', Icons.settings, AppConstants.routeSettings,
        AppTheme.textSecondary),
  ];

  // المدير
  static const List<_MenuItem> _managerMenu = [
    _MenuItem('الموظفين', Icons.people, AppConstants.routeEmployees,
        AppTheme.infoColor),
    _MenuItem(
        'الأجهزة', Icons.phone_android, '/admin/devices', AppTheme.accentColor),
    _MenuItem('الحضور', Icons.access_time, AppConstants.routeAttendance,
        AppTheme.successColor),
    _MenuItem('المنتجات', Icons.inventory_2, AppConstants.routeProducts,
        AppTheme.accentColor),
    _MenuItem('المخزون', Icons.inventory, AppConstants.routeStock,
        AppTheme.successColor),
    _MenuItem('العملاء', Icons.people_alt, AppConstants.routeCustomers,
        AppTheme.primaryColor),
    _MenuItem('الفواتير', Icons.receipt_long, AppConstants.routeInvoices,
        AppTheme.accentColor),
    _MenuItem('الصيانة', Icons.build, AppConstants.routeMaintenance,
        AppTheme.errorColor),
    _MenuItem('التقارير', Icons.bar_chart, AppConstants.routeReports,
        AppTheme.infoColor),
  ];

  // المحاسب
  static const List<_MenuItem> _accountantMenu = [
    _MenuItem('الحضور', Icons.access_time, AppConstants.routeAttendance,
        AppTheme.successColor),
    _MenuItem('الرواتب', Icons.payments, AppConstants.routePayrolls,
        AppTheme.primaryColor),
    _MenuItem('السلف', Icons.money_off, AppConstants.routeAdvances,
        AppTheme.errorColor),
    _MenuItem('العملاء', Icons.people_alt, AppConstants.routeCustomers,
        AppTheme.infoColor),
    _MenuItem('الفواتير', Icons.receipt_long, AppConstants.routeInvoices,
        AppTheme.accentColor),
    _MenuItem('التقارير', Icons.bar_chart, AppConstants.routeReports,
        AppTheme.primaryColor),
  ];

  // أمين المخزن
  static const List<_MenuItem> _storekeeperMenu = [
    _MenuItem('المنتجات', Icons.inventory_2, AppConstants.routeProducts,
        AppTheme.accentColor),
    _MenuItem('التصنيفات', Icons.category, AppConstants.routeCategories,
        AppTheme.infoColor),
    _MenuItem('الماركات', Icons.branding_watermark, AppConstants.routeBrands,
        AppTheme.warningColor),
    _MenuItem('المخازن', Icons.warehouse, AppConstants.routeWarehouses,
        AppTheme.primaryColor),
    _MenuItem('المخزون', Icons.inventory, AppConstants.routeStock,
        AppTheme.successColor),
  ];

  // الكاشير
  static const List<_MenuItem> _cashierMenu = [
    _MenuItem('الفواتير', Icons.receipt_long, AppConstants.routeInvoices,
        AppTheme.primaryColor),
    _MenuItem('العملاء', Icons.people_alt, AppConstants.routeCustomers,
        AppTheme.infoColor),
    _MenuItem('المنتجات', Icons.inventory_2, AppConstants.routeProducts,
        AppTheme.accentColor),
    _MenuItem('الصيانة', Icons.build, AppConstants.routeMaintenance,
        AppTheme.warningColor),
  ];

  // الفني
  static const List<_MenuItem> _technicianMenu = [
    _MenuItem('الصيانة', Icons.build, AppConstants.routeMaintenance,
        AppTheme.primaryColor),
    _MenuItem('المنتجات', Icons.inventory_2, AppConstants.routeProducts,
        AppTheme.accentColor),
    _MenuItem('العملاء', Icons.people_alt, AppConstants.routeCustomers,
        AppTheme.infoColor),
  ];
}

// =====================================================
// Widget: كارت القايمة
// =====================================================
class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.color.withValues(alpha: isDark ? 0.3 : 0.15),
            width: 1.5,
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.color,
                    item.color.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(item.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// Model: عنصر القائمة
// =====================================================
class _MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const _MenuItem(this.title, this.icon, this.route, this.color);
}

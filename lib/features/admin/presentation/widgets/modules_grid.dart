// lib/features/admin/presentation/widgets/modules_grid.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class ModulesGrid extends StatelessWidget {
  final String roleCode;

  const ModulesGrid({super.key, required this.roleCode});

  @override
  Widget build(BuildContext context) {
    final modules = _getModules();

    if (modules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'لا توجد صلاحيات متاحة لهذا الدور',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
            ),
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];
        return GlassCard(
          onTap: () => context.go(m.route),
          padding: const EdgeInsets.all(10),
          borderRadius: 18,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      m.color,
                      m.color.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: m.color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(m.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  m.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_Module> _getModules() {
    switch (roleCode) {
      case AppConstants.roleAdmin:
        return _adminModules;
      case AppConstants.roleManager:
        return _managerModules;
      case AppConstants.roleAccountant:
        return _accountantModules;
      case AppConstants.roleStorekeeper:
        return _storekeeperModules;
      case AppConstants.roleCashier:
        return _cashierModules;
      case AppConstants.roleTechnician:
        return _technicianModules;
      default:
        return [];
    }
  }

  // =====================================================
  // الأدمن — كل حاجة
  // =====================================================
  static const List<_Module> _adminModules = [
    _Module('المنتجات', Icons.inventory_2, '/products', AppTheme.accentColor),
    _Module('المخازن', Icons.warehouse, '/warehouses', AppTheme.primaryColor),
    _Module('العملاء', Icons.people_alt, '/customers', AppTheme.infoColor),
    _Module('البيانات', Icons.receipt_long, '/invoices', AppTheme.successColor),
    _Module('الموظفين', Icons.people, '/employees', AppTheme.warningColor),
    _Module(
      'الأجهزة',
      Icons.phone_android,
      '/admin/devices',
      AppTheme.accentColor,
    ),
    _Module('الحضور', Icons.access_time, '/attendance', AppTheme.infoColor),
    _Module('الإجازات', Icons.beach_access, '/leaves', AppTheme.warningColor),
    _Module('الرواتب', Icons.payments, '/payrolls', AppTheme.primaryColor),
    _Module('السلف', Icons.money_off, '/advances', AppTheme.errorColor),
    _Module(
      'الصيانة',
      Icons.build_circle,
      '/maintenance',
      AppTheme.errorColor,
    ),
    _Module('التقارير', Icons.bar_chart, '/reports', AppTheme.accentColor),
    _Module('الإعدادات', Icons.settings, '/settings', AppTheme.textSecondary),
  ];

  // =====================================================
  // المدير
  // =====================================================
  static const List<_Module> _managerModules = [
    _Module('المنتجات', Icons.inventory_2, '/products', AppTheme.accentColor),
    _Module('المخازن', Icons.warehouse, '/warehouses', AppTheme.primaryColor),
    _Module('العملاء', Icons.people_alt, '/customers', AppTheme.infoColor),
    _Module('البيانات', Icons.receipt_long, '/invoices', AppTheme.successColor),
    _Module('الموظفين', Icons.people, '/employees', AppTheme.warningColor),
    _Module(
      'الأجهزة',
      Icons.phone_android,
      '/admin/devices',
      AppTheme.accentColor,
    ),
    _Module(
      'الصيانة',
      Icons.build_circle,
      '/maintenance',
      AppTheme.errorColor,
    ),
    _Module('الإجازات', Icons.beach_access, '/leaves', AppTheme.warningColor),
    _Module('التقارير', Icons.bar_chart, '/reports', AppTheme.accentColor),
    _Module('الإعدادات', Icons.settings, '/settings', AppTheme.textSecondary),
  ];

  // =====================================================
  // المحاسب
  // =====================================================
  static const List<_Module> _accountantModules = [
    _Module('الحضور', Icons.access_time, '/attendance', AppTheme.infoColor),
    _Module('الرواتب', Icons.payments, '/payrolls', AppTheme.primaryColor),
    _Module('السلف', Icons.money_off, '/advances', AppTheme.errorColor),
    _Module('العملاء', Icons.people_alt, '/customers', AppTheme.infoColor),
    _Module(
      'الموردين',
      Icons.local_shipping,
      '/suppliers',
      AppTheme.warningColor,
    ),
    _Module('البيانات', Icons.receipt_long, '/invoices', AppTheme.successColor),
    _Module(
      'الصيانة',
      Icons.build_circle,
      '/maintenance',
      AppTheme.errorColor,
    ),
    _Module('التقارير', Icons.bar_chart, '/reports', AppTheme.accentColor),
    _Module('الإعدادات', Icons.settings, '/settings', AppTheme.textSecondary),
  ];

  // =====================================================
  // أمين المخزن
  // =====================================================
  static const List<_Module> _storekeeperModules = [
    _Module('المنتجات', Icons.inventory_2, '/products', AppTheme.accentColor),
    _Module('التصنيفات', Icons.category, '/categories', AppTheme.infoColor),
    _Module('المخازن', Icons.warehouse, '/warehouses', AppTheme.primaryColor),
    _Module('المخزون', Icons.inventory, '/stock', AppTheme.successColor),
    _Module(
      'الموردين',
      Icons.local_shipping,
      '/suppliers',
      AppTheme.warningColor,
    ),
    _Module(
      'الصيانة',
      Icons.build_circle,
      '/maintenance',
      AppTheme.errorColor,
    ),
  ];

  // =====================================================
  // الكاشير
  // =====================================================
  static const List<_Module> _cashierModules = [
    _Module('البيانات', Icons.receipt_long, '/invoices', AppTheme.successColor),
    _Module('العملاء', Icons.people_alt, '/customers', AppTheme.infoColor),
    _Module('المنتجات', Icons.inventory_2, '/products', AppTheme.accentColor),
    _Module(
      'الصيانة',
      Icons.build_circle,
      '/maintenance',
      AppTheme.errorColor,
    ),
    _Module('التقارير', Icons.bar_chart, '/reports', AppTheme.accentColor),
  ];

  // =====================================================
  // الفني
  // =====================================================
  static const List<_Module> _technicianModules = [
    _Module(
      'الصيانة',
      Icons.build_circle,
      '/maintenance',
      AppTheme.errorColor,
    ),
    _Module('المنتجات', Icons.inventory_2, '/products', AppTheme.accentColor),
    _Module('العملاء', Icons.people_alt, '/customers', AppTheme.infoColor),
  ];
}

class _Module {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const _Module(this.title, this.icon, this.route, this.color);
}

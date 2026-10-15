// lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleCode = ref.watch(currentRoleProvider);
    final isAdmin = roleCode == AppConstants.roleAdmin;
    final isAdminOrManager = isAdmin || roleCode == AppConstants.roleManager;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'الإعدادات',
        actions: [
          ThemeToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // =====================================================
          // 🔴 لو مش أدمن/مدير → يعرض بس المظهر + معلومات النظام
          // =====================================================
          if (!isAdminOrManager) ...[
            _buildSectionHeader(context, 'عام'),
            _settingsTile(
              context,
              icon: Icons.palette_outlined,
              iconColor: AppTheme.primaryColor,
              title: 'المظهر',
              subtitle: 'فاتح / غامق / تلقائي',
              onTap: () => context.go('/settings/appearance'),
            ),
            _settingsTile(
              context,
              icon: Icons.info_outline,
              iconColor: AppTheme.infoColor,
              title: 'معلومات النظام',
              subtitle: 'الإصدار والتحديثات',
              onTap: () => context.go('/settings/system-info'),
            ),
          ] else ...[
            // =====================================================
            // 🟢 للأدمن/المدير → كل الإعدادات
            // =====================================================

            _buildSectionHeader(context, 'الشركة'),
            _settingsTile(
              context,
              icon: Icons.business_outlined,
              iconColor: AppTheme.primaryColor,
              title: 'معلومات الشركة',
              subtitle: 'الاسم، الشعار، الاتصال',
              onTap: () => context.go('/settings/company'),
            ),
            _settingsTile(
              context,
              icon: Icons.location_on_outlined,
              iconColor: AppTheme.errorColor,
              title: 'موقع الشركة',
              subtitle: 'الإحداثيات ونطاق الحضور',
              onTap: () => context.go('/settings/location'),
            ),

            _buildSectionHeader(context, 'المالية'),

            _settingsTile(
              context,
              icon: Icons.attach_money,
              iconColor: AppTheme.successColor,
              title: 'العملة والضرائب',
              subtitle: 'الرمز، الكود، نسبة الضريبة',
              onTap: () => context.go('/settings/currency'),
            ),
            _settingsTile(
              context,
              icon: Icons.payments_outlined,
              iconColor: AppTheme.infoColor,
              title: 'الرواتب',
              subtitle: 'بداية دورة الرواتب',
              onTap: () => context.go('/settings/payroll'),
            ),

            _buildSectionHeader(context, 'الحضور'),

            _settingsTile(
              context,
              icon: Icons.access_time,
              iconColor: AppTheme.warningColor,
              title: 'مواعيد الشيفت',
              subtitle: 'البداية والنهاية والتسامح',
              onTap: () => context.go('/settings/attendance'),
            ),

            _buildSectionHeader(context, 'المخزون'),

            _settingsTile(
              context,
              icon: Icons.inventory_2_outlined,
              iconColor: AppTheme.accentColor,
              title: 'إعدادات المخزون',
              subtitle: 'حد المخزون المنخفض',
              onTap: () => context.go('/settings/inventory'),
            ),

            // =====================================================
            // الوظائف والأقسام (مرحلة 2 - نخليها معلقة)
            // =====================================================
            _buildSectionHeader(context, 'الموارد البشرية'),
            _settingsTile(
              context,
              icon: Icons.work_outline,
              iconColor: AppTheme.primaryColor,
              title: 'الوظائف',
              subtitle: 'إدارة المسميات الوظيفية',
              onTap: () => context.go('/settings/job-titles'),
            ),
            _settingsTile(
              context,
              icon: Icons.business_center_outlined,
              iconColor: AppTheme.infoColor,
              title: 'الأقسام',
              subtitle: 'إدارة أقسام الشركة',
              onTap: () => context.go('/settings/departments'),
            ),

            _buildSectionHeader(context, 'عام'),
            _settingsTile(
              context,
              icon: Icons.palette_outlined,
              iconColor: AppTheme.primaryColor,
              title: 'المظهر',
              subtitle: 'فاتح / غامق / تلقائي',
              onTap: () => context.go('/settings/appearance'),
            ),
            _settingsTile(
              context,
              icon: Icons.info_outline,
              iconColor: AppTheme.infoColor,
              title: 'معلومات النظام',
              subtitle: 'الإصدار والتحديثات',
              onTap: () => context.go('/settings/system-info'),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // Widgets
  // =====================================================

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondaryColor(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.textSecondaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/settings/presentation/screens/appearance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'المظهر',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'اختر الوضع اللي يريحك',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 20),
          _themeOption(
            context,
            ref,
            mode: ThemeMode.light,
            icon: Icons.light_mode,
            title: 'الوضع الفاتح',
            subtitle: 'ألوان فاتحة ومريحة للعين',
            current: themeMode,
            color: const Color(0xFFFFB300),
          ),
          const SizedBox(height: 12),
          _themeOption(
            context,
            ref,
            mode: ThemeMode.dark,
            icon: Icons.dark_mode,
            title: 'الوضع الغامق',
            subtitle: 'ألوان غامقة مريحة ليلاً',
            current: themeMode,
            color: const Color(0xFF6A1B9A),
          ),
          const SizedBox(height: 12),
          _themeOption(
            context,
            ref,
            mode: ThemeMode.system,
            icon: Icons.brightness_auto,
            title: 'تلقائي',
            subtitle: 'يتبع إعدادات النظام',
            current: themeMode,
            color: AppTheme.infoColor,
          ),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode current,
    required Color color,
  }) {
    final isDark = AppTheme.isDark(context);
    final isSelected = current == mode;

    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).setTheme(mode),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.dividerColor),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
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
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor(context),
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

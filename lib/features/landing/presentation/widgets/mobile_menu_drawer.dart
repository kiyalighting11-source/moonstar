// lib/features/landing/presentation/widgets/mobile_menu_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';

class MobileMenuDrawer extends ConsumerWidget {
  const MobileMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final isLoggedIn = ref.watch(currentUserProvider) != null;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =====================================================
            // Header
            // =====================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryLight,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.star,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moonstar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'نظام الفواتير الآلي',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // =====================================================
            // Nav Items
            // =====================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _menuItem(
                    context: context,
                    icon: Icons.home_outlined,
                    label: 'الرئيسية',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppConstants.routeLanding);
                    },
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    label: 'منتجاتنا',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppConstants.routeShop);
                    },
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.info_outline,
                    label: 'عن الشركة',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppConstants.routeAbout);
                    },
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.contact_phone_outlined,
                    label: 'اتصل بنا',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppConstants.routeContact);
                    },
                  ),

                  // موقع الشركة
                  _menuItem(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: 'موقع الشركة',
                    onTap: () async {
                      Navigator.pop(context);
                      await _launchUrl(CompanyInfo.googleMapsUrl);
                    },
                  ),

                  // واتساب
                  _menuItem(
                    context: context,
                    icon: Icons.chat_outlined,
                    label: 'واتساب',
                    onTap: () async {
                      Navigator.pop(context);
                      await _launchUrl(
                        'https://wa.me/2${CompanyInfo.whatsapp}',
                      );
                    },
                  ),

                  const Divider(height: 32, indent: 20, endIndent: 20),

                  // Theme toggle
                  _menuItem(
                    context: context,
                    icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    label: isDarkMode ? 'الوضع الفاتح' : 'الوضع الغامق',
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // =====================================================
            // Login / Dashboard button
            // =====================================================
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(
                    isLoggedIn
                        ? AppConstants.routeHome
                        : AppConstants.routeLogin,
                  );
                },
                icon: Icon(
                  isLoggedIn ? Icons.dashboard_outlined : Icons.login,
                ),
                label: Text(
                  isLoggedIn ? 'لوحة التحكم' : 'تسجيل الدخول',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Menu Item
  // =====================================================
  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textColor(context),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
    );
  }

  // =====================================================
  // Helper — Launch URL
  // =====================================================
  static Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

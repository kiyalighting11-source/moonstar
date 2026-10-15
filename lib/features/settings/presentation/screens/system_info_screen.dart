// lib/features/settings/presentation/screens/system_info_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class SystemInfoScreen extends ConsumerWidget {
  const SystemInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'معلومات النظام',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =====================================================
          // Logo + اسم الشركة
          // =====================================================
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'الإصدار ${AppConstants.appVersion}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // =====================================================
          // معلومات الشركة
          // =====================================================
          _section(context, 'الشركة', [
            settingsAsync.when(
              loading: () => _rowLoading(),
              error: (_, __) => _row(context, Icons.business, 'الاسم', '—'),
              data: (s) => Column(
                children: [
                  _row(
                    context,
                    Icons.business_outlined,
                    'الاسم',
                    s?.companyName ?? '—',
                  ),
                  if (s?.companyPhone != null)
                    _row(
                      context,
                      Icons.phone_outlined,
                      'الهاتف',
                      s!.companyPhone!,
                    ),
                  if (s?.companyEmail != null)
                    _row(
                      context,
                      Icons.email_outlined,
                      'الإيميل',
                      s!.companyEmail!,
                    ),
                  if (s?.companyAddress != null)
                    _row(
                      context,
                      Icons.location_on_outlined,
                      'العنوان',
                      s!.companyAddress!,
                    ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // =====================================================
          // معلومات المستخدم
          // =====================================================
          _section(context, 'المستخدم الحالي', [
            profileAsync.when(
              loading: () => _rowLoading(),
              error: (_, __) => _row(context, Icons.person, 'الاسم', '—'),
              data: (p) => Column(
                children: [
                  _row(
                    context,
                    Icons.person_outline,
                    'الاسم',
                    p?['full_name'] as String? ?? '—',
                  ),
                  _row(
                    context,
                    Icons.email_outlined,
                    'الإيميل',
                    p?['email'] as String? ?? '—',
                  ),
                  _row(
                    context,
                    Icons.verified_user_outlined,
                    'الدور',
                    _getRoleName(p),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // =====================================================
          // معلومات التطبيق
          // =====================================================
          _section(context, 'التطبيق', [
            _row(context, Icons.apps, 'الاسم', AppConstants.appName),
            _row(context, Icons.numbers, 'الإصدار', AppConstants.appVersion),
            _row(
              context,
              Icons.calendar_today_outlined,
              'تاريخ الإنشاء',
              '2026',
            ),
          ]),

          const SizedBox(height: 24),

          // =====================================================
          // حقوق
          // =====================================================
          Center(
            child: Column(
              children: [
                Text(
                  '© 2026 ${AppConstants.companyName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'جميع الحقوق محفوظة',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getRoleName(Map<String, dynamic>? profile) {
    if (profile == null) return '—';
    final role = profile['roles'];
    if (role is Map) {
      final code = role['code'] as String?;
      if (code == null) return '—';
      return AppConstants.roleNamesAr[code] ?? code;
    }
    return '—';
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final isDark = AppTheme.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondaryColor(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowLoading() {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: LinearProgressIndicator(),
    );
  }
}

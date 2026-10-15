// lib/core/widgets/dashboard_app_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// AppBar موحّد لكل صفحات الداشبورد
/// - سهم رجوع → يروح للداشبورد الرئيسية (/home)
/// - لون شفاف
/// - Actions اختيارية
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const DashboardAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppTheme.textColor(context),
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'الرجوع للداشبورد',
              onPressed: () => context.go(AppConstants.routeHome),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textColor(context),
        ),
      ),
      actions: actions,
    );
  }
}

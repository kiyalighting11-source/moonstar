// lib/core/widgets/theme_toggle_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// زرار تبديل Dark/Light — استخدمه في أي AppBar
class ThemeToggleButton extends ConsumerWidget {
  final Color? iconColor;
  final double? size;

  const ThemeToggleButton({
    super.key,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: iconColor ?? AppTheme.textColor(context),
        size: size ?? 24,
      ),
      tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الغامق',
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggle();
      },
    );
  }
}

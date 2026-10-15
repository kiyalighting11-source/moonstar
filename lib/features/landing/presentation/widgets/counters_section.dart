// lib/features/landing/presentation/widgets/counters_section.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/scroll_animations.dart';

class CountersSection extends StatelessWidget {
  const CountersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isMobile ? 24 : 60,
      ),
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 40,
          vertical: isMobile ? 20 : 48,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryColor,
              AppTheme.primaryLight,
            ],
          ),
          borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: isMobile ? 20 : 40,
              offset: Offset(0, isMobile ? 10 : 20),
            ),
          ],
        ),
        // ⭐ دايماً Row (بالعرض)
        child: _buildHorizontalRow(context, isMobile),
      ),
    );
  }

  // =====================================================
  // Horizontal Row (بالعرض على كل الأحجام)
  // =====================================================
  Widget _buildHorizontalRow(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildCounter(
            context: context,
            value: CompanyInfo.statsProducts,
            prefix: '+',
            label: 'منتج',
            icon: Icons.inventory_2,
            isMobile: isMobile,
          ),
        ),
        _divider(isMobile),
        Expanded(
          child: _buildCounter(
            context: context,
            value: CompanyInfo.statsClients,
            prefix: '+',
            label: 'عميل',
            icon: Icons.people,
            isMobile: isMobile,
          ),
        ),
        _divider(isMobile),
        Expanded(
          child: _buildCounter(
            context: context,
            value: CompanyInfo.statsYears,
            prefix: '+',
            label: 'سنة خبرة',
            icon: Icons.emoji_events,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isMobile) {
    return Container(
      width: 1,
      height: isMobile ? 40 : 60,
      color: Colors.white.withValues(alpha: 0.2),
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 20),
    );
  }

  // =====================================================
  // Single Counter
  // =====================================================
  Widget _buildCounter({
    required BuildContext context,
    required int value,
    required String prefix,
    required String label,
    required IconData icon,
    required bool isMobile,
  }) {
    // 📏 الأحجام — أصغر على الموبايل
    final iconSize = isMobile ? 14.0 : 28.0;
    final iconPadding = isMobile ? 6.0 : 14.0;
    final numberSize = isMobile ? 20.0 : 42.0;
    final labelSize = isMobile ? 10.0 : 14.0;
    final spacing1 = isMobile ? 6.0 : 16.0;
    final spacing2 = isMobile ? 2.0 : 4.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isMobile ? 8 : 14),
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),

        SizedBox(height: spacing1),

        // Number
        CountUpOnScroll(
          end: value,
          prefix: prefix,
          style: TextStyle(
            fontSize: numberSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: spacing2),

        // Label
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: labelSize,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

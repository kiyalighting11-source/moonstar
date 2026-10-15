// lib/core/utils/responsive_helper.dart

import 'package:flutter/material.dart';

/// أداة للكشف عن حجم الشاشة
/// - بتستخدم breakpoints زي Material Design
class ResponsiveHelper {
  // =====================================================
  // Breakpoints
  // =====================================================
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  static const double desktopMax = 1440;

  // =====================================================
  // Detection
  // =====================================================
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= tabletMax && w < desktopMax;
  }

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopMax;

  /// هل هي ويب/ديسكتوب؟
  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  // =====================================================
  // Grid Columns للمنتجات
  // =====================================================
  static int getProductGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 2;
    if (w < 900) return 3;
    if (w < 1200) return 4;
    if (w < 1600) return 5;
    return 6;
  }

  // =====================================================
  // Padding / Spacing
  // =====================================================
  static double getHorizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 12;
    if (w < 1024) return 24;
    return 40;
  }

  // =====================================================
  // Page Size (Pagination)
  // =====================================================
  static int getPageSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 12; // موبايل
    if (w < 1024) return 15; // تابلت
    return 20; // ديسكتوب
  }

  // =====================================================
  // Height بتاع الـ Header
  // =====================================================
  static double getHeaderHeight(BuildContext context) {
    if (isMobile(context)) return 60;
    return 72;
  }
}

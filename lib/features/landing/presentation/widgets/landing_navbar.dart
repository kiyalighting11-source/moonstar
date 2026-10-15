// lib/features/landing/presentation/widgets/landing_navbar.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/providers/auth_provider.dart';

class LandingNavbar extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final bool isTransparent;
  final bool showNavLinks;
  final VoidCallback? onSearchTap;
  final VoidCallback? onMenuTap;

  const LandingNavbar({
    super.key,
    required this.scrollController,
    this.isTransparent = true,
    this.showNavLinks = true,
    this.onSearchTap,
    this.onMenuTap,
  });

  @override
  ConsumerState<LandingNavbar> createState() => _LandingNavbarState();
}

class _LandingNavbarState extends ConsumerState<LandingNavbar> {
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final scrolled = widget.scrollController.offset > 50;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isCompact = screenWidth < 1024; // ⭐ للتابلت والديسكتوب الصغير
    final isLoggedIn = ref.watch(currentUserProvider) != null;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final isCurrentlyTransparent = widget.isTransparent && !_isScrolled;

    // Glassmorphism Colors
    final glassColor = isCurrentlyTransparent
        ? Colors.transparent
        : (isDark
            ? const Color(0xFF0F1115).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.35));

    final borderColor = isCurrentlyTransparent
        ? Colors.transparent
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.5));

    final textColor =
        isCurrentlyTransparent ? Colors.white : AppTheme.textColor(context);

    final iconColor =
        isCurrentlyTransparent ? Colors.white : AppTheme.textColor(context);

    // 📏 ارتفاعات مختلفة
    final navHeight = isMobile ? 90.0 : (isCompact ? 110.0 : 130.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isCurrentlyTransparent ? 0 : 20,
          sigmaY: isCurrentlyTransparent ? 0 : 20,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: glassColor,
            border: Border(
              bottom: BorderSide(color: borderColor),
            ),
            boxShadow: !isCurrentlyTransparent
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getHorizontalPadding(context),
            ),
            child: SizedBox(
              height: navHeight,
              child: isMobile
                  ? _buildMobileLayout(
                      context: context,
                      isCurrentlyTransparent: isCurrentlyTransparent,
                      iconColor: iconColor,
                    )
                  : _buildDesktopLayout(
                      context: context,
                      textColor: textColor,
                      iconColor: iconColor,
                      isLoggedIn: isLoggedIn,
                      isDarkMode: isDarkMode,
                      isCurrentlyTransparent: isCurrentlyTransparent,
                      isCompact: isCompact,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Desktop Layout
  // =====================================================
  Widget _buildDesktopLayout({
    required BuildContext context,
    required Color textColor,
    required Color iconColor,
    required bool isLoggedIn,
    required bool isDarkMode,
    required bool isCurrentlyTransparent,
    required bool isCompact,
  }) {
    return Row(
      children: [
        // Logo
        _buildLogo(
          context: context,
          isCurrentlyTransparent: isCurrentlyTransparent,
          isMobile: false,
        ),

        SizedBox(width: isCompact ? 16 : 32),

        // ⭐ Nav Links — بس على الشاشات الكبيرة (> 1024)
        if (!isCompact && widget.showNavLinks) ...[
          _navLink(
            label: 'الرئيسية',
            onTap: () => context.go(AppConstants.routeLanding),
            color: textColor,
          ),
          _navLink(
            label: 'منتجاتنا',
            onTap: () => context.go(AppConstants.routeShop),
            color: textColor,
          ),
          _navLink(
            label: 'عن الشركة',
            onTap: () => context.go(AppConstants.routeAbout),
            color: textColor,
          ),
          _navLink(
            label: 'اتصل بنا',
            onTap: () => context.go(AppConstants.routeContact),
            color: textColor,
          ),
        ],

        const Spacer(),

        // Search
        if (widget.onSearchTap != null) ...[
          if (!isCompact) ...[
            _searchBox(context, onTap: widget.onSearchTap!),
            const SizedBox(width: 12),
          ] else
            IconButton(
              icon: Icon(
                Icons.search,
                color: iconColor,
                size: 22,
              ),
              tooltip: 'بحث',
              onPressed: widget.onSearchTap,
            ),
        ],

        // Theme Toggle
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: iconColor,
            size: isCompact ? 22 : 26,
          ),
          tooltip: isDarkMode ? 'الوضع الفاتح' : 'الوضع الغامق',
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggle();
          },
        ),

        const SizedBox(width: 4),

        // ⭐ Login Button — بس على الشاشات الكبيرة، على الصغيرة أيقونة
        if (isCompact)
          IconButton(
            icon: Icon(
              isLoggedIn ? Icons.dashboard_outlined : Icons.login,
              color: iconColor,
              size: 22,
            ),
            tooltip: isLoggedIn ? 'لوحة التحكم' : 'تسجيل الدخول',
            onPressed: () {
              context.go(
                isLoggedIn ? AppConstants.routeHome : AppConstants.routeLogin,
              );
            },
          )
        else
          _loginButton(context, isLoggedIn, isCurrentlyTransparent),

        // ⭐ Hamburger للـ Desktop الصغير
        if (isCompact)
          IconButton(
            icon: Icon(
              Icons.menu,
              color: iconColor,
              size: 26,
            ),
            tooltip: 'القائمة',
            onPressed: widget.onMenuTap,
          ),
      ],
    );
  }

  // =====================================================
  // Mobile Layout
  // =====================================================
  Widget _buildMobileLayout({
    required BuildContext context,
    required bool isCurrentlyTransparent,
    required Color iconColor,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Logo في النص
        Center(
          child: _buildLogo(
            context: context,
            isCurrentlyTransparent: isCurrentlyTransparent,
            isMobile: true,
          ),
        ),

        // Hamburger على اليمين
        Positioned(
          right: 0,
          child: IconButton(
            icon: Icon(
              Icons.menu,
              color: iconColor,
              size: 30,
            ),
            tooltip: 'القائمة',
            onPressed: widget.onMenuTap,
          ),
        ),

        // Theme Toggle على الشمال
        Positioned(
          left: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onSearchTap != null)
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: iconColor,
                    size: 22,
                  ),
                  onPressed: widget.onSearchTap,
                ),
              IconButton(
                icon: Icon(
                  ref.watch(themeModeProvider) == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: iconColor,
                  size: 22,
                ),
                tooltip: 'تبديل الوضع',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggle();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Logo
  // =====================================================
  Widget _buildLogo({
    required BuildContext context,
    required bool isCurrentlyTransparent,
    required bool isMobile,
  }) {
    // 📏 أحجام مختلفة حسب الشاشة
    final screenWidth = MediaQuery.of(context).size.width;
    final logoHeight =
        screenWidth < 600 ? 60.0 : (screenWidth < 1024 ? 80.0 : 100.0);
    final minWidth =
        screenWidth < 600 ? 100.0 : (screenWidth < 1024 ? 140.0 : 180.0);
    final maxWidth =
        screenWidth < 600 ? 160.0 : (screenWidth < 1024 ? 220.0 : 280.0);

    return InkWell(
      onTap: () => context.go(AppConstants.routeLanding),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: logoHeight,
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.star,
                  color: isCurrentlyTransparent
                      ? Colors.white
                      : AppTheme.primaryColor,
                  size: logoHeight * 0.6,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Nav Link
  // =====================================================
  Widget _navLink({
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Search Box (Desktop)
  // =====================================================
  Widget _searchBox(
    BuildContext context, {
    required VoidCallback onTap,
  }) {
    final isCurrentlyTransparent = widget.isTransparent && !_isScrolled;
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isCurrentlyTransparent
              ? Colors.white.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentlyTransparent
                ? Colors.white.withValues(alpha: 0.3)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 18,
              color: isCurrentlyTransparent
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondaryColor(context),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'ابحث...',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentlyTransparent
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Login Button (Desktop)
  // =====================================================
  Widget _loginButton(
    BuildContext context,
    bool isLoggedIn,
    bool isTransparent,
  ) {
    final bgColor = isTransparent ? Colors.white : AppTheme.primaryColor;
    final fgColor = isTransparent ? AppTheme.primaryColor : Colors.white;

    return ElevatedButton.icon(
      onPressed: () {
        context.go(
          isLoggedIn ? AppConstants.routeHome : AppConstants.routeLogin,
        );
      },
      icon: Icon(
        isLoggedIn ? Icons.dashboard_outlined : Icons.login,
        size: 18,
      ),
      label: Text(
        isLoggedIn ? 'لوحة التحكم' : 'تسجيل الدخول',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

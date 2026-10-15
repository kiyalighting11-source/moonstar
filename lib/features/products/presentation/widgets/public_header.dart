// lib/features/products/presentation/widgets/public_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/providers/auth_provider.dart';

/// Header الزوار
/// - يختفي لما تسكرول (Hide on Scroll)
/// - فيه: Logo + Nav Links + Search + Login
class PublicHeader extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onSearchTap;
  final VoidCallback? onMenuTap;

  const PublicHeader({
    super.key,
    required this.scrollController,
    this.onSearchTap,
    this.onMenuTap,
  });

  @override
  ConsumerState<PublicHeader> createState() => _PublicHeaderState();
}

class _PublicHeaderState extends ConsumerState<PublicHeader> {
  bool _isVisible = true;
  double _lastOffset = 0;

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

    final offset = widget.scrollController.offset;
    final diff = offset - _lastOffset;

    // لو المستخدم بيسكرول لتحت → نخفي
    // لو بيسكرول لفوق → نظهر
    if (diff > 5 && offset > 100 && _isVisible) {
      setState(() => _isVisible = false);
    } else if (diff < -5 && !_isVisible) {
      setState(() => _isVisible = true);
    }

    _lastOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isLoggedIn = ref.watch(currentUserProvider) != null;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: _isVisible ? ResponsiveHelper.getHeaderHeight(context) : 0,
      child: ClipRect(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isVisible ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F1115).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getHorizontalPadding(context),
              ),
              child: Row(
                children: [
                  // =====================================================
                  // Hamburger (mobile only)
                  // =====================================================
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: widget.onMenuTap,
                      color: AppTheme.textColor(context),
                    ),

                  // =====================================================
                  // Logo
                  // =====================================================
                  InkWell(
                    onTap: () => context.go(AppConstants.routeShop),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLight,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 10),
                            Text(
                              AppConstants.companyName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // =====================================================
                  // Nav Links (desktop only)
                  // =====================================================
                  if (!isMobile) ...[
                    _navLink(
                      context,
                      label: 'المنتجات',
                      onTap: () => context.go(AppConstants.routeShop),
                    ),
                    _navLink(
                      context,
                      label: 'الفئات',
                      onTap: () {
                        // ينزل لـ chips التصنيفات
                        if (widget.scrollController.hasClients) {
                          widget.scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                    _navLink(
                      context,
                      label: 'اتصل بنا',
                      onTap: () => _showContactDialog(context),
                    ),
                  ],

                  const Spacer(),

                  // =====================================================
                  // Search (desktop)
                  // =====================================================
                  if (!isMobile) _searchBox(context, onTap: widget.onSearchTap),

                  if (!isMobile) const SizedBox(width: 12),

                  // Search icon (mobile)
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: widget.onSearchTap,
                      color: AppTheme.textColor(context),
                    ),

                  // =====================================================
                  // Theme Toggle
                  // =====================================================
                  IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    ),
                    tooltip: isDarkMode ? 'الوضع الفاتح' : 'الوضع الغامق',
                    color: AppTheme.textColor(context),
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                  ),

                  // =====================================================
                  // Login / Dashboard
                  // =====================================================
                  if (isMobile)
                    IconButton(
                      icon: Icon(
                        isLoggedIn ? Icons.dashboard_outlined : Icons.login,
                      ),
                      tooltip: isLoggedIn ? 'لوحة التحكم' : 'تسجيل الدخول',
                      color: AppTheme.textColor(context),
                      onPressed: () {
                        context.go(
                          isLoggedIn
                              ? AppConstants.routeHome
                              : AppConstants.routeLogin,
                        );
                      },
                    )
                  else
                    _loginButton(context, isLoggedIn),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Nav Link
  // =====================================================
  Widget _navLink(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
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
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor(context),
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
    VoidCallback? onTap,
  }) {
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 260,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 18,
              color: AppTheme.textSecondaryColor(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ابحث عن منتج...',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '/',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondaryColor(context),
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
  Widget _loginButton(BuildContext context, bool isLoggedIn) {
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
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // =====================================================
  // Contact Dialog
  // =====================================================
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            AppTheme.isDark(context) ? const Color(0xFF151A23) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('اتصل بنا'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _contactRow(
              context,
              Icons.phone_outlined,
              'الهاتف',
              '01000000000',
            ),
            const SizedBox(height: 10),
            _contactRow(
              context,
              Icons.email_outlined,
              'الإيميل',
              'info@moonstar.com',
            ),
            const SizedBox(height: 10),
            _contactRow(
              context,
              Icons.location_on_outlined,
              'العنوان',
              'القاهرة، مصر',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textSecondaryColor(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor(context),
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
        ),
      ],
    );
  }
}

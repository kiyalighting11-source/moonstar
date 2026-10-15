// lib/features/products/presentation/widgets/pagination_bar.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getHorizontalPadding(context),
        vertical: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            AppTheme.isDark(context) ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: isMobile
          ? _buildMobilePagination(context)
          : _buildDesktopPagination(context),
    );
  }

  // =====================================================
  // Mobile: ◀ 1 / 5 ▶
  // =====================================================
  Widget _buildMobilePagination(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navButton(
          context,
          icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        Text(
          'صفحة $currentPage من $totalPages',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        _navButton(
          context,
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }

  // =====================================================
  // Desktop: Full pagination
  // =====================================================
  Widget _buildDesktopPagination(BuildContext context) {
    final pages = _calculatePages();

    return Row(
      children: [
        // عدد السجلات
        Text(
          'عرض ${(currentPage - 1) * pageSize + 1}–'
          '${(currentPage * pageSize).clamp(0, totalItems)} '
          'من $totalItems',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),

        const Spacer(),

        // Prev
        _navButton(
          context,
          icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),

        const SizedBox(width: 8),

        // Page numbers
        ...pages.map((page) {
          if (page == -1) {
            // ellipsis
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '...',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _pageButton(context, page),
          );
        }),

        const SizedBox(width: 8),

        // Next
        _navButton(
          context,
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }

  Widget _pageButton(BuildContext context, int page) {
    final isActive = page == currentPage;

    return GestureDetector(
      onTap: () => onPageChanged(page),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor
              : (AppTheme.isDark(context)
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor
                : (AppTheme.isDark(context)
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.dividerColor),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : AppTheme.textColor(context),
          ),
        ),
      ),
    );
  }

  Widget _navButton(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.isDark(context)
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.isDark(context)
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.dividerColor,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppTheme.textColor(context)
              : AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // =====================================================
  // حساب أرقام الصفحات (1, 2, ..., 10, 11)
  // =====================================================
  List<int> _calculatePages() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }

    final pages = <int>[1];
    final start = (currentPage - 1).clamp(2, totalPages - 4);
    final end = (currentPage + 1).clamp(4, totalPages - 2);

    if (start > 2) pages.add(-1); // ellipsis

    for (int i = start; i <= end; i++) {
      if (i > 1 && i < totalPages) pages.add(i);
    }

    if (end < totalPages - 1) pages.add(-1); // ellipsis

    pages.add(totalPages);
    return pages;
  }
}

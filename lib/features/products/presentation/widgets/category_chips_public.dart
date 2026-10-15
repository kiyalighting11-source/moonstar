// lib/features/products/presentation/widgets/category_chips_public.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../data/models/category_model.dart';
import '../../providers/products_provider.dart';
import '../../providers/shop_provider.dart';

class CategoryChipsPublic extends ConsumerWidget {
  const CategoryChipsPublic({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainCategoriesAsync = ref.watch(mainCategoriesProvider);
    final filter = ref.watch(shopFilterProvider);
    final isDark = AppTheme.isDark(context);

    return mainCategoriesAsync.when(
      loading: () => const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox(height: 44),
      data: (mainCategories) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getHorizontalPadding(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== المستوى الرئيسي =====
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildChip(
                      context: context,
                      label: 'الكل',
                      icon: Icons.apps,
                      selected: filter.categoryId == null,
                      isMain: true,
                      onTap: () {
                        ref.read(shopFilterProvider.notifier).state =
                            filter.copyWith(clearCategory: true);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...mainCategories.map((cat) {
                      final isSelected =
                          _isCategoryOrParentSelected(cat, filter.categoryId);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildChip(
                          context: context,
                          label: cat.name,
                          icon: _getCategoryIcon(cat.name),
                          selected: isSelected,
                          isMain: true,
                          onTap: () {
                            if (filter.categoryId == cat.id) {
                              ref.read(shopFilterProvider.notifier).state =
                                  filter.copyWith(clearCategory: true);
                            } else {
                              ref.read(shopFilterProvider.notifier).state =
                                  filter.copyWith(categoryId: cat.id);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // ===== المستوى الفرعي =====
              if (filter.categoryId != null) ...[
                const SizedBox(height: 8),
                _buildSubLevel(
                  context: context,
                  ref: ref,
                  mainCategoryId: filter.categoryId!,
                  currentSelected: filter.categoryId,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // Sub Level
  // =====================================================
  Widget _buildSubLevel({
    required BuildContext context,
    required WidgetRef ref,
    required String mainCategoryId,
    required String? currentSelected,
    required bool isDark,
  }) {
    final subsAsync = ref.watch(subcategoriesProvider(mainCategoryId));

    return subsAsync.when(
      loading: () => const SizedBox(height: 44),
      error: (_, __) => const SizedBox.shrink(),
      data: (subs) {
        if (subs.isEmpty) return const SizedBox.shrink();

        String? selectedSubId;
        for (final sub in subs) {
          if (_isCategoryOrParentSelected(sub, currentSelected)) {
            selectedSubId = sub.id;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...subs.map((sub) {
                    final isSelected = selectedSubId == sub.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildChip(
                        context: context,
                        label: sub.name,
                        icon: _getCategoryIcon(sub.name),
                        selected: isSelected,
                        isMain: false,
                        onTap: () {
                          ref.read(shopFilterProvider.notifier).state =
                              _withCategoryId(ref, sub.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (selectedSubId != null) ...[
              const SizedBox(height: 8),
              _buildSubSubLevel(
                context: context,
                ref: ref,
                subCategoryId: selectedSubId,
                currentSelected: currentSelected,
              ),
            ],
          ],
        );
      },
    );
  }

  // =====================================================
  // SubSub Level
  // =====================================================
  Widget _buildSubSubLevel({
    required BuildContext context,
    required WidgetRef ref,
    required String subCategoryId,
    required String? currentSelected,
  }) {
    final subSubsAsync = ref.watch(subcategoriesProvider(subCategoryId));

    return subSubsAsync.when(
      loading: () => const SizedBox(height: 44),
      error: (_, __) => const SizedBox.shrink(),
      data: (subSubs) {
        if (subSubs.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...subSubs.map((subSub) {
                final isSelected = currentSelected == subSub.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChip(
                    context: context,
                    label: subSub.name,
                    icon: _getCategoryIcon(subSub.name),
                    selected: isSelected,
                    isMain: false,
                    isLeaf: true,
                    onTap: () {
                      ref.read(shopFilterProvider.notifier).state =
                          _withCategoryId(ref, subSub.id);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // Helpers
  // =====================================================

  bool _isCategoryOrParentSelected(CategoryModel cat, String? selectedId) {
    if (selectedId == null) return false;
    if (cat.id == selectedId) return true;

    for (final child in cat.children) {
      if (_isCategoryOrParentSelected(child, selectedId)) return true;
    }
    return false;
  }

  ShopFilter _withCategoryId(WidgetRef ref, String categoryId) {
    final current = ref.read(shopFilterProvider);
    return current.copyWith(
      categoryId: categoryId,
      page: 1,
    );
  }

  // =====================================================
  // Chip Builder
  // =====================================================
  Widget _buildChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    bool isMain = false,
    bool isLeaf = false,
  }) {
    final isDark = AppTheme.isDark(context);

    final selectedColor = isMain
        ? AppTheme.primaryColor
        : (isLeaf ? AppTheme.accentColor : AppTheme.infoColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor
              : (isDark ? const Color(0xFF151A23) : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? selectedColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : AppTheme.textSecondaryColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textColor(context),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Icons
  // =====================================================
  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase().trim();

    if (lower == 'led screen') return Icons.tv;
    if (lower == 'stage lighting') return Icons.lightbulb;
    if (lower == 'truss') return Icons.construction;

    if (lower == 'indoor') return Icons.home;
    if (lower == 'outdoor') return Icons.wb_sunny;

    if (lower == 'moving heads') return Icons.highlight;
    if (lower == 'beam') return Icons.flash_on;
    if (lower == 'led') return Icons.lightbulb_outline;
    if (lower == 'par lights') return Icons.flashlight_on;
    if (lower == 'wall washer') return Icons.wallpaper;
    if (lower == 'laser light') return Icons.graphic_eq;
    if (lower == 'effect light') return Icons.auto_awesome;
    if (lower == 'smoke machine') return Icons.cloud;
    if (lower == 'strobe light') return Icons.bolt;
    if (lower == 'console') return Icons.dashboard;
    if (lower == 'theater lighting') return Icons.theater_comedy;
    if (lower == 'video light') return Icons.videocam;
    if (lower == 'cob') return Icons.light_mode;

    if (lower == 'aluminum') return Icons.view_module;
    if (lower == 'iron') return Icons.fence;
    if (lower == 'layer') return Icons.layers;
    if (lower == 'stage') return Icons.stadium;
    if (lower == 'truss accessories') return Icons.build_circle;

    if (lower == '28.5' || lower == '40') return Icons.straighten;

    return Icons.category;
  }
}

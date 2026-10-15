// lib/features/products/presentation/public_products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../landing/presentation/widgets/landing_navbar.dart';
import '../../landing/presentation/widgets/mobile_menu_drawer.dart';
import '../providers/shop_provider.dart';
import 'widgets/category_chips_public.dart';
import 'widgets/pagination_bar.dart';
import 'widgets/public_product_card.dart';

class PublicProductsScreen extends ConsumerStatefulWidget {
  const PublicProductsScreen({super.key});

  @override
  ConsumerState<PublicProductsScreen> createState() =>
      _PublicProductsScreenState();
}

class _PublicProductsScreenState extends ConsumerState<PublicProductsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 600;
    if (show != _showBackToTop) {
      setState(() => _showBackToTop = show);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(shopProductsProvider);
    final filter = ref.watch(shopFilterProvider);

    ref.listen<ShopFilter>(shopFilterProvider, (prev, next) {
      if (prev?.categoryId != next.categoryId || prev?.search != next.search) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const MobileMenuDrawer(),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              // =====================================================
              // Navbar
              // =====================================================
              LandingNavbar(
                scrollController: _scrollController,
                isTransparent: false,
                showNavLinks: true,
                onSearchTap: () => _showSearchDialog(context, ref),
                onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),

              // =====================================================
              // المحتوى
              // =====================================================
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(shopProductsProvider);
                    await ref.read(shopProductsProvider.future);
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(child: _buildHero(context)),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: CategoryChipsPublic(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildActiveFiltersBar(context, ref, filter),
                      ),
                      SliverToBoxAdapter(
                        child: _buildTitleBar(context, ref, filter),
                      ),
                      productsAsync.when(
                        loading: () => const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, _) => SliverFillRemaining(
                          child: _buildError(context, ref, e),
                        ),
                        data: (data) {
                          if (data.products.isEmpty) {
                            return SliverFillRemaining(
                              child: _buildEmpty(context, ref, filter),
                            );
                          }

                          final columns =
                              ResponsiveHelper.getProductGridColumns(context);

                          return SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.getHorizontalPadding(
                                context,
                              ),
                              vertical: 8,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = data.products[index];
                                  return PublicProductCard(
                                    product: product,
                                    onTap: () => context.go(
                                      '/shop/product/${product.id}',
                                    ),
                                  );
                                },
                                childCount: data.products.length,
                              ),
                            ),
                          );
                        },
                      ),
                      SliverToBoxAdapter(
                        child: productsAsync.maybeWhen(
                          data: (data) => PaginationBar(
                            currentPage: data.currentPage,
                            totalPages: data.totalPages,
                            totalItems: data.totalCount,
                            pageSize: data.pageSize,
                            onPageChanged: (page) {
                              ref.read(shopFilterProvider.notifier).state =
                                  filter.copyWith(page: page);
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildFooter(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Back to Top
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: _showBackToTop ? 30 : -80,
            right: 30,
            child: _buildBackToTopButton(),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Hero
  // =====================================================
  Widget _buildHero(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getHorizontalPadding(context),
        vertical: isMobile ? 20 : 32,
      ),
      child: Column(
        children: [
          Text(
            'منتجاتنا',
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'استعرض كل منتجات Moonstar من إضاءة وشاشات وتراس',
            style: TextStyle(
              fontSize: isMobile ? 13 : 16,
              color: AppTheme.textSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Active Filters Bar
  // =====================================================
  Widget _buildActiveFiltersBar(
    BuildContext context,
    WidgetRef ref,
    ShopFilter filter,
  ) {
    final hasFilters = filter.search != null || filter.categoryId != null;
    if (!hasFilters) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getHorizontalPadding(context),
        vertical: 4,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'الفلاتر المفعّلة:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          if (filter.search != null)
            _activeFilterChip(
              context: context,
              label: '"${filter.search}"',
              icon: Icons.search,
              onRemove: () {
                ref.read(shopFilterProvider.notifier).state =
                    filter.copyWith(clearSearch: true, page: 1);
              },
            ),
          TextButton.icon(
            onPressed: () {
              ref.read(shopFilterProvider.notifier).state = const ShopFilter();
            },
            icon: const Icon(Icons.close, size: 14),
            label: const Text(
              'مسح الكل',
              style: TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 10,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Title Bar + Sort
  // =====================================================
  Widget _buildTitleBar(
    BuildContext context,
    WidgetRef ref,
    ShopFilter filter,
  ) {
    final productsAsync = ref.watch(shopProductsProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getHorizontalPadding(context),
        vertical: 8,
      ),
      child: Row(
        children: [
          productsAsync.maybeWhen(
            data: (data) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${data.totalCount} منتج',
                key: ValueKey(data.totalCount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.isDark(context)
                  ? const Color(0xFF151A23)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.isDark(context)
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filter.sortBy,
                icon: const Icon(Icons.sort, size: 18),
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textColor(context),
                ),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('الأحدث')),
                  DropdownMenuItem(value: 'name', child: Text('الاسم')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(shopFilterProvider.notifier).state =
                        filter.copyWith(sortBy: v, page: 1);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Empty
  // =====================================================
  Widget _buildEmpty(
    BuildContext context,
    WidgetRef ref,
    ShopFilter filter,
  ) {
    final hasFilters = filter.search != null || filter.categoryId != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'مفيش نتائج' : 'مفيش منتجات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'جرب تبحث بكلمة تانية أو تختار تصنيف مختلف'
                  : 'لا توجد منتجات متاحة حالياً',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(shopFilterProvider.notifier).state =
                      const ShopFilter();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('مسح الفلاتر'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Error
  // =====================================================
  Widget _buildError(BuildContext context, WidgetRef ref, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(shopProductsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Footer
  // =====================================================
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getHorizontalPadding(context),
        vertical: 32,
      ),
      child: Column(
        children: [
          Divider(
            color: AppTheme.isDark(context)
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 20),
          Text(
            '© 2026 Moonstar ERP — جميع الحقوق محفوظة',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Back to Top
  // =====================================================
  Widget _buildBackToTopButton() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _showBackToTop ? 1.0 : 0.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _scrollToTop,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryLight,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Search Dialog
  // =====================================================
  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    _searchController.text = ref.read(shopFilterProvider).search ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = AppTheme.isDark(context);

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF151A23) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن منتج...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (v) {
                          _applySearch(ref, v);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _applySearch(ref, _searchController.text);
                      Navigator.pop(ctx);
                    },
                    child: const Text('بحث'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applySearch(WidgetRef ref, String value) {
    final v = value.trim();
    final current = ref.read(shopFilterProvider);
    ref.read(shopFilterProvider.notifier).state = current.copyWith(
      search: v.isEmpty ? null : v,
      clearSearch: v.isEmpty,
      page: 1,
    );
  }
}

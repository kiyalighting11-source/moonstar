// lib/features/products/presentation/products_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_guard.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import '../providers/products_provider.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/empty_products.dart';
import 'widgets/product_card.dart';
import 'widgets/product_list_tile.dart';
import 'widgets/products_search_bar.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final isLoggedIn = AuthGuard.isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'المنتجات',
        actions: [
          // ⭐ زرار تبديل الثيم
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeModeProvider);
              final isDark = themeMode == ThemeMode.dark;

              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: AppTheme.textColor(context),
                ),
                tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الغامق',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggle();
                },
              );
            },
          ),

          // ⭐ تبديل بين Grid و List
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            tooltip: _isGridView ? 'عرض كقائمة' : 'عرض كشبكة',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/products/add'),
              icon: const Icon(Icons.add),
              label: const Text('منتج جديد'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: ProductsSearchBar(
              initialValue: ref.read(productsFilterProvider).search,
              onChanged: (value) {
                ref.read(productsFilterProvider.notifier).state =
                    ref.read(productsFilterProvider).copyWith(search: value);
              },
            ),
          ),

          // فلتر التصنيفات
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: CategoryFilterChips(),
          ),

          const SizedBox(height: 8),

          // قائمة المنتجات
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ: $e',
                      style: TextStyle(color: AppTheme.textColor(context)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(filteredProductsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyProducts(
                    onAdd:
                        isLoggedIn ? () => context.go('/products/add') : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(filteredProductsProvider);
                    await ref.read(filteredProductsProvider.future);
                  },
                  child: _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 200 + (index * 30),
                              ),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: ProductCard(
                                product: product,
                                onTap: () =>
                                    context.go('/products/${product.id}'),
                              ),
                            );
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                          itemCount: products.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 200 + (index * 30),
                              ),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(20 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: ProductListTile(
                                product: product,
                                onTap: () =>
                                    context.go('/products/${product.id}'),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

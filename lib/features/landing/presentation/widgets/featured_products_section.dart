// lib/features/landing/presentation/widgets/featured_products_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/scroll_animations.dart';
import '../../../products/providers/shop_provider.dart';
import '../../../products/presentation/widgets/public_product_card.dart';

class FeaturedProductsSection extends ConsumerWidget {
  const FeaturedProductsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    // ⭐ بنستخدم shopProductsProvider (public — بدون أسعار)
    final productsAsync = ref.watch(shopProductsProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isMobile ? 60 : 100,
      ),
      color: Colors.transparent,
      child: Column(
        children: [
          // Header
          FadeInOnScroll(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'منتجاتنا',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'أحدث المنتجات',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 42,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColor(context),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Text(
                    'اكتشف أحدث منتجاتنا من الإضاءة والشاشات والتراس',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: AppTheme.textSecondaryColor(context),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Products Grid
          productsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'حدث خطأ في تحميل المنتجات',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
            data: (data) {
              final products = data.products;

              if (products.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد منتجات حالياً',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                );
              }

              final featured = products.take(8).toList();
              final columns = isMobile ? 2 : 4;

              return Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: featured.length,
                    itemBuilder: (context, index) {
                      return FadeInOnScroll(
                        delay: Duration(milliseconds: 80 * index),
                        child: PublicProductCard(
                          product: featured[index],
                          onTap: () => context.go(
                            '/shop/product/${featured[index].id}',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  FadeInOnScroll(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/shop'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'تصفح كل المنتجات',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 36,
                          vertical: isMobile ? 16 : 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 8,
                        shadowColor:
                            AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

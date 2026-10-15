// lib/features/products/providers/shop_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product_model.dart';
import 'products_provider.dart';

// =====================================================
// Filter للـ Shop
// =====================================================
class ShopFilter {
  final String? search;
  final String? categoryId;
  final int page;
  final String sortBy;

  const ShopFilter({
    this.search,
    this.categoryId,
    this.page = 1,
    this.sortBy = 'newest',
  });

  ShopFilter copyWith({
    String? search,
    String? categoryId,
    int? page,
    String? sortBy,
    bool clearSearch = false,
    bool clearCategory = false,
  }) {
    return ShopFilter(
      search: clearSearch ? null : (search ?? this.search),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final shopFilterProvider = StateProvider<ShopFilter>((ref) {
  return const ShopFilter();
});

// =====================================================
// Paginated Products
// =====================================================
class PaginatedProducts {
  final List<ProductModel> products;
  final int totalCount;
  final int currentPage;
  final int pageSize;

  PaginatedProducts({
    required this.products,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  bool get hasNext => currentPage < totalPages;
  bool get hasPrevious => currentPage > 1;
}

/// ⭐ Shop للزوار (بدون أسعار)
final shopProductsProvider =
    FutureProvider.autoDispose<PaginatedProducts>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  final filter = ref.watch(shopFilterProvider);

  const pageSize = 20;

  final result = await repo.getPublicShopProducts(
    page: filter.page,
    pageSize: pageSize,
    search: filter.search,
    categoryId: filter.categoryId,
    sortBy: filter.sortBy,
  );

  return PaginatedProducts(
    products: result['products'] as List<ProductModel>,
    totalCount: result['totalCount'] as int,
    currentPage: filter.page,
    pageSize: pageSize,
  );
});

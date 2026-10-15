// lib/features/products/providers/products_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/products_repository.dart';

// =====================================================
// Repository Provider
// =====================================================
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository();
});

// =====================================================
// قائمة المنتجات (للمسجلين)
// =====================================================
final productsListProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return await repo.getAllProducts();
});

// =====================================================
// فلاتر المنتجات
// =====================================================
class ProductsFilter {
  final String? search;
  final String? categoryId;
  final bool onlyActive;

  const ProductsFilter({
    this.search,
    this.categoryId,
    this.onlyActive = false,
  });

  ProductsFilter copyWith({
    String? search,
    String? categoryId,
    bool? onlyActive,
    bool clearSearch = false,
    bool clearCategory = false,
  }) {
    return ProductsFilter(
      search: clearSearch ? null : (search ?? this.search),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      onlyActive: onlyActive ?? this.onlyActive,
    );
  }
}

final productsFilterProvider = StateProvider<ProductsFilter>((ref) {
  return const ProductsFilter();
});

// =====================================================
// قائمة المنتجات المفلترة (للمسجلين)
// =====================================================
final filteredProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  final filter = ref.watch(productsFilterProvider);

  return await repo.getAllProducts(
    onlyActive: filter.onlyActive,
    categoryId: filter.categoryId,
    search: filter.search,
  );
});

// =====================================================
// منتج واحد (للمسجلين — بالأسعار)
// =====================================================
final productByIdProvider =
    FutureProvider.autoDispose.family<ProductModel?, String>((ref, id) async {
  final repo = ref.watch(productsRepositoryProvider);
  return await repo.getProductById(id);
});

// =====================================================
// ⭐ منتج واحد (للزوار — من public_products)
// =====================================================
final publicProductByIdProvider =
    FutureProvider.autoDispose.family<ProductModel?, String>((ref, id) async {
  final repo = ref.watch(productsRepositoryProvider);
  return await repo.getPublicProductById(id);
});

// =====================================================
// قائمة التصنيفات (شجرة كاملة)
// =====================================================
final categoriesTreeProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return await repo.getAllCategories();
});

// =====================================================
// التصنيفات الرئيسية فقط
// =====================================================
final mainCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return await repo.getMainCategories();
});

// =====================================================
// التصنيفات الفرعية لأب معين
// =====================================================
final subcategoriesProvider = FutureProvider.autoDispose
    .family<List<CategoryModel>, String>((ref, parentId) async {
  final repo = ref.watch(productsRepositoryProvider);
  return await repo.getSubcategories(parentId);
});

// =====================================================
// Controller: عمليات المنتجات
// =====================================================
class ProductsController extends StateNotifier<AsyncValue<void>> {
  ProductsController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final ProductsRepository _repo;
  final Ref _ref;

  Future<bool> createProduct(ProductModel product) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createProduct(product);
      state = const AsyncValue.data(null);
      _ref.invalidate(productsListProvider);
      _ref.invalidate(filteredProductsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProduct(product);
      state = const AsyncValue.data(null);
      _ref.invalidate(productsListProvider);
      _ref.invalidate(filteredProductsProvider);
      _ref.invalidate(productByIdProvider(product.id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteProduct(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(productsListProvider);
      _ref.invalidate(filteredProductsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final productsControllerProvider =
    StateNotifierProvider<ProductsController, AsyncValue<void>>((ref) {
  return ProductsController(ref.read(productsRepositoryProvider), ref);
});

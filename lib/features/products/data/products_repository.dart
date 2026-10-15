// lib/features/products/data/products_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import 'models/category_model.dart';
import 'models/product_model.dart';

class ProductsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // PRODUCTS (للموظفين المسجلين)
  // =====================================================

  Future<List<ProductModel>> getAllProducts({
    bool onlyActive = false,
    String? categoryId,
    String? search,
  }) async {
    var query = _supabase.from(AppConstants.productsTable).select('*');

    if (onlyActive) query = query.eq('is_active', true);

    if (categoryId != null) {
      final descendantIds = await _getDescendantCategoryIds(categoryId);

      if (descendantIds.isNotEmpty) {
        query = query.inFilter('category_id', descendantIds);
      } else {
        query = query.eq('category_id', categoryId);
      }
    }

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name', '%${search.trim()}%');
    }

    final data = await query.order('created_at', ascending: false);
    final products =
        (data as List).map((e) => ProductModel.fromJson(e)).toList();

    return await _attachCategoryNames(products);
  }

  Future<ProductModel?> getProductById(String id) async {
    final data = await _supabase
        .from(AppConstants.productsTable)
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    final product = ProductModel.fromJson(data);
    final list = await _attachCategoryNames([product]);
    return list.first;
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    final userId = _supabase.auth.currentUser?.id;

    final data = await _supabase
        .from(AppConstants.productsTable)
        .insert({
          ...product.toJson(),
          'created_by': userId,
        })
        .select('*')
        .single();

    return ProductModel.fromJson(data);
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final data = await _supabase
        .from(AppConstants.productsTable)
        .update(product.toJson())
        .eq('id', product.id)
        .select('*')
        .single();

    return ProductModel.fromJson(data);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase
        .from(AppConstants.productsTable)
        .update({'is_active': false}).eq('id', id);
  }

  Future<void> hardDeleteProduct(String id) async {
    await _supabase.from(AppConstants.productsTable).delete().eq('id', id);
  }

  // =====================================================
  // 🛒 SHOP (للموظفين المسجلين — بالأسعار والمخزون)
  // =====================================================

  Future<Map<String, dynamic>> getShopProducts({
    required int page,
    required int pageSize,
    String? search,
    String? categoryId,
    String sortBy = 'newest',
  }) async {
    List<String>? descendantIds;
    if (categoryId != null) {
      descendantIds = await _getDescendantCategoryIds(categoryId);
      if (descendantIds.isEmpty) {
        descendantIds = [categoryId];
      }
    }

    // 1) العدد
    var countQuery = _supabase
        .from(AppConstants.productsTable)
        .select('id')
        .eq('is_active', true);

    if (descendantIds != null && descendantIds.isNotEmpty) {
      countQuery = countQuery.inFilter('category_id', descendantIds);
    }
    if (search != null && search.trim().isNotEmpty) {
      countQuery = countQuery.ilike('name', '%${search.trim()}%');
    }

    final countResult = await countQuery.count();
    final totalCount = countResult.count;

    // 2) البيانات
    var dataQuery = _supabase
        .from(AppConstants.productsTable)
        .select('*')
        .eq('is_active', true);

    if (descendantIds != null && descendantIds.isNotEmpty) {
      dataQuery = dataQuery.inFilter('category_id', descendantIds);
    }
    if (search != null && search.trim().isNotEmpty) {
      dataQuery = dataQuery.ilike('name', '%${search.trim()}%');
    }

    final orderedQuery = _applyOrder(dataQuery, sortBy);

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final finalQuery = orderedQuery.range(from, to);

    final data = await finalQuery;
    final products =
        (data as List).map((e) => ProductModel.fromJson(e)).toList();

    final productsWithCats = await _attachCategoryNames(products);

    return {
      'products': productsWithCats,
      'totalCount': totalCount,
    };
  }

  // =====================================================
  // ⭐ SHOP للزوار (بدون أسعار ومخزون)
  // =====================================================

  /// ⭐ جلب المنتجات للزوار من View العام
  Future<Map<String, dynamic>> getPublicShopProducts({
    required int page,
    required int pageSize,
    String? search,
    String? categoryId,
    String sortBy = 'newest',
  }) async {
    List<String>? descendantIds;
    if (categoryId != null) {
      descendantIds = await _getDescendantCategoryIds(categoryId);
      if (descendantIds.isEmpty) {
        descendantIds = [categoryId];
      }
    }

    // 1) العدد
    var countQuery = _supabase.from('public_products').select('id');

    if (descendantIds != null && descendantIds.isNotEmpty) {
      countQuery = countQuery.inFilter('category_id', descendantIds);
    }
    if (search != null && search.trim().isNotEmpty) {
      countQuery = countQuery.ilike('name', '%${search.trim()}%');
    }

    final countResult = await countQuery.count();
    final totalCount = countResult.count;

    // 2) البيانات
    var dataQuery = _supabase.from('public_products').select('*');

    if (descendantIds != null && descendantIds.isNotEmpty) {
      dataQuery = dataQuery.inFilter('category_id', descendantIds);
    }
    if (search != null && search.trim().isNotEmpty) {
      dataQuery = dataQuery.ilike('name', '%${search.trim()}%');
    }

    final orderedQuery = _applyOrder(dataQuery, sortBy);

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final data = await orderedQuery.range(from, to);

    final products =
        (data as List).map((e) => ProductModel.fromPublicJson(e)).toList();

    final productsWithCats = await _attachCategoryNames(products);

    return {
      'products': productsWithCats,
      'totalCount': totalCount,
    };
  }

  /// ⭐ منتج واحد للزوار (من public_products)
  Future<ProductModel?> getPublicProductById(String id) async {
    final data = await _supabase
        .from('public_products')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    final product = ProductModel.fromPublicJson(data);
    final list = await _attachCategoryNames([product]);
    return list.first;
  }

  // =====================================================
  // CATEGORIES
  // =====================================================

  Future<List<CategoryModel>> getAllCategories() async {
    final data = await _supabase
        .from(AppConstants.categoriesTable)
        .select('*')
        .eq('is_active', true)
        .order('name');

    final all = (data as List).map((e) => CategoryModel.fromJson(e)).toList();
    return _buildTree(all);
  }

  Future<List<CategoryModel>> getMainCategories() async {
    final data = await _supabase
        .from(AppConstants.categoriesTable)
        .select('*')
        .filter('parent_id', 'is', null)
        .eq('is_active', true)
        .order('name');

    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<CategoryModel>> getSubcategories(String parentId) async {
    final data = await _supabase
        .from(AppConstants.categoriesTable)
        .select('*')
        .eq('parent_id', parentId)
        .eq('is_active', true)
        .order('name');

    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final data = await _supabase
        .from(AppConstants.categoriesTable)
        .insert(category.toJson())
        .select()
        .single();

    return CategoryModel.fromJson(data);
  }

  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final data = await _supabase
        .from(AppConstants.categoriesTable)
        .update(category.toJson())
        .eq('id', category.id)
        .select()
        .single();

    return CategoryModel.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from(AppConstants.categoriesTable).delete().eq('id', id);
  }

  // =====================================================
  // HELPERS
  // =====================================================

  Future<List<String>> _getDescendantCategoryIds(String categoryId) async {
    try {
      final data = await _supabase.rpc(
        'get_category_descendants',
        params: {'p_category_id': categoryId},
      );

      if (data is List) {
        return data.map((e) => (e as Map)['id'] as String).toList();
      }
      return [];
    } catch (_) {
      return [categoryId];
    }
  }

  Future<List<ProductModel>> _attachCategoryNames(
    List<ProductModel> products,
  ) async {
    if (products.isEmpty) return products;

    final catsData = await _supabase
        .from(AppConstants.categoriesTable)
        .select('id, name, parent_id');

    final catMap = <String, Map<String, dynamic>>{};
    for (final c in (catsData as List)) {
      catMap[c['id'] as String] = {
        'name': c['name'] as String,
        'parent_id': c['parent_id'] as String?,
      };
    }

    return products.map((p) {
      if (p.categoryId == null || !catMap.containsKey(p.categoryId)) {
        return p;
      }

      final cat = catMap[p.categoryId!]!;
      final catName = cat['name'] as String;
      final parentId = cat['parent_id'] as String?;

      String? rootName;
      String? currentParentId = parentId;
      int safetyCounter = 0;

      while (currentParentId != null && safetyCounter < 10) {
        final parent = catMap[currentParentId];
        if (parent == null) break;

        rootName = parent['name'] as String?;
        currentParentId = parent['parent_id'] as String?;
        safetyCounter++;
      }

      return p.copyWith(
        categoryName: catName,
        categoryParentName: rootName,
      );
    }).toList();
  }

  List<CategoryModel> _buildTree(List<CategoryModel> flat) {
    final mainCategories = flat.where((c) => c.parentId == null).toList();

    return mainCategories.map((main) {
      final children = flat.where((c) => c.parentId == main.id).toList();

      final withGrandchildren = children.map((child) {
        final grandchildren =
            flat.where((c) => c.parentId == child.id).toList();
        return child.copyWith(children: grandchildren);
      }).toList();

      return main.copyWith(children: withGrandchildren);
    }).toList();
  }

  // =====================================================
  // ⭐ Sort — بعد ما شلنا price_low / price_high
  // =====================================================
  dynamic _applyOrder(dynamic query, String sortBy) {
    switch (sortBy) {
      case 'name':
        return query.order('name', ascending: true);
      case 'newest':
      default:
        return query.order('created_at', ascending: false);
    }
  }
}

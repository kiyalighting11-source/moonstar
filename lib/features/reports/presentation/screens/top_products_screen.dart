// lib/features/reports/presentation/screens/top_products_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/top_product_model.dart';
import '../../providers/reports_provider.dart';

class TopProductsScreen extends ConsumerStatefulWidget {
  const TopProductsScreen({super.key});

  @override
  ConsumerState<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends ConsumerState<TopProductsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reportFilterProvider);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('الأكثر مبيعاً'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppTheme.textColor(context),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'الرجوع للداشبورد',
          onPressed: () => context.go(AppConstants.routeHome),
        ),
        actions: const [
          ThemeToggleButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor(context),
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_2, size: 20),
              text: 'المنتجات',
            ),
            Tab(
              icon: Icon(Icons.people, size: 20),
              text: 'العملاء',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  filter.labelAr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(context),
                _buildCustomersTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Products Tab
  // =====================================================
  Widget _buildProductsTab(BuildContext context) {
    final async = ref.watch(topProductsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorBox(context, e),
      data: (products) {
        if (products.isEmpty) {
          return _emptyState(
            context,
            icon: Icons.inventory_2,
            title: 'مفيش منتجات مبيعاً',
            subtitle: 'في الفترة المحددة',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(topProductsProvider);
            await ref.read(topProductsProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _productTile(context, products[i], i + 1),
          ),
        );
      },
    );
  }

  Widget _productTile(BuildContext context, TopProductModel product, int rank) {
    final rankColor = _rankColor(rank);
    final isDark = AppTheme.isDark(context);
    final avgPriceLabel =
        '${Helpers.formatCurrency(product.averagePrice, decimals: 0)} / وحدة';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(
                color: rankColor.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: _productImage(context, product.productImageUrl),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.productSku ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _miniChip(
                      '${product.totalQuantity.toStringAsFixed(0)} قطعة',
                      AppTheme.infoColor,
                    ),
                    const SizedBox(width: 4),
                    _miniChip(
                      '${product.ordersCount} طلب',
                      AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatCurrency(product.totalRevenue, decimals: 0),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                avgPriceLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Customers Tab
  // =====================================================
  Widget _buildCustomersTab(BuildContext context) {
    final async = ref.watch(topCustomersProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorBox(context, e),
      data: (customers) {
        if (customers.isEmpty) {
          return _emptyState(
            context,
            icon: Icons.people,
            title: 'مفيش عملاء',
            subtitle: 'في الفترة المحددة',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(topCustomersProvider);
            await ref.read(topCustomersProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _customerTile(context, customers[i], i + 1),
          ),
        );
      },
    );
  }

  Widget _customerTile(
    BuildContext context,
    Map<String, dynamic> customer,
    int rank,
  ) {
    final rankColor = _rankColor(rank);
    final isDark = AppTheme.isDark(context);

    final name = customer['customer_name'] as String? ?? 'بدون اسم';
    final phone = customer['phone'] as String?;
    final totalSales = (customer['total_sales'] as num?)?.toDouble() ?? 0;
    final count = customer['invoices_count'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(
                color: rankColor.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            child: Text(
              Helpers.initials(name),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _miniChip(
                  '$count بيان',
                  AppTheme.infoColor,
                ),
              ],
            ),
          ),
          Text(
            Helpers.formatCurrency(totalSales, decimals: 0),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Helpers
  // =====================================================
  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppTheme.textSecondary;
  }

  Widget _productImage(BuildContext context, String? url) {
    final isDark = AppTheme.isDark(context);

    if (url == null || url.isEmpty) {
      return Container(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.lightBg,
        child: Icon(
          Icons.image_outlined,
          color: AppTheme.textSecondaryColor(context),
          size: 24,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.lightBg,
      ),
      errorWidget: (_, __, ___) => Container(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.lightBg,
        child: Icon(
          Icons.broken_image_outlined,
          color: AppTheme.textSecondaryColor(context),
          size: 24,
        ),
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(BuildContext context, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

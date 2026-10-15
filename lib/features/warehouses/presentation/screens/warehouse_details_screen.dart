// lib/features/warehouses/presentation/screens/warehouse_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/providers/warehouses_provider.dart';
import '../widgets/stock_item_tile.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class WarehouseDetailsScreen extends ConsumerStatefulWidget {
  final String warehouseId;

  const WarehouseDetailsScreen({super.key, required this.warehouseId});

  @override
  ConsumerState<WarehouseDetailsScreen> createState() =>
      _WarehouseDetailsScreenState();
}

class _WarehouseDetailsScreenState
    extends ConsumerState<WarehouseDetailsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warehouseAsync = ref.watch(warehouseByIdProvider(widget.warehouseId));
    final stockAsync = ref.watch(stockByWarehouseProvider(widget.warehouseId));
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: warehouseAsync.maybeWhen(
          data: (w) => w?.name ?? 'تفاصيل المخزن',
          orElse: () => 'تفاصيل المخزن',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.go('/warehouses/edit/${widget.warehouseId}'),
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'جرد',
            onPressed: () =>
                context.go('/warehouses/${widget.warehouseId}/count'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'الحركات',
            onPressed: () =>
                context.go('/warehouses/${widget.warehouseId}/movements'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.go('/warehouses/${widget.warehouseId}/movements/add'),
        icon: const Icon(Icons.add),
        label: const Text('حركة جديدة'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151A23) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  ref.read(stockFilterProvider.notifier).state =
                      ref.read(stockFilterProvider).copyWith(search: v);
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.primaryColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(stockFilterProvider.notifier).state =
                                ref.read(stockFilterProvider);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // قائمة المخزون
          Expanded(
            child: stockAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'حدث خطأ: $e',
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
              ),
              data: (stocks) {
                if (stocks.isEmpty) {
                  return Center(
                    child: Text(
                      'لا يوجد مخزون في هذا المخزن',
                      style: TextStyle(color: AppTheme.textColor(context)),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        stockByWarehouseProvider(widget.warehouseId));
                    await ref.read(
                        stockByWarehouseProvider(widget.warehouseId).future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: stocks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return StockItemTile(stock: stocks[index]);
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

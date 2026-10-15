// lib/features/warehouses/presentation/screens/stock_movements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/providers/warehouses_provider.dart';
import '../widgets/movement_tile.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class StockMovementsScreen extends ConsumerWidget {
  final String? warehouseId;

  const StockMovementsScreen({super.key, this.warehouseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (warehouseId != null) {
        final filter = ref.read(movementsFilterProvider);
        if (filter.warehouseId != warehouseId) {
          ref.read(movementsFilterProvider.notifier).state =
              filter.copyWith(warehouseId: warehouseId);
        }
      }
    });

    final movementsAsync = ref.watch(movementsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'حركات المخزون',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: warehouseId != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.go('/warehouses/$warehouseId/movements/add'),
              icon: const Icon(Icons.add),
              label: const Text('حركة جديدة'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: movementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ: $e',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(movementsListProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (movements) {
          if (movements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد حركات',
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(movementsListProvider);
              await ref.read(movementsListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: movements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return MovementTile(movement: movements[index]);
              },
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(ref: ref),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final WidgetRef ref;

  const _FilterBottomSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(movementsFilterProvider);
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فلترة الحركات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'النوع:',
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip(context, 'الكل', filter.type == null, () {
                ref.read(movementsFilterProvider.notifier).state =
                    filter.copyWith(clearType: true);
              }),
              _chip(context, 'إدخال', filter.type == 'purchase_in', () {
                ref.read(movementsFilterProvider.notifier).state =
                    filter.copyWith(type: 'purchase_in');
              }),
              _chip(context, 'إخراج', filter.type == 'sale_out', () {
                ref.read(movementsFilterProvider.notifier).state =
                    filter.copyWith(type: 'sale_out');
              }),
              _chip(context, 'تسوية', filter.type == 'adjustment', () {
                ref.read(movementsFilterProvider.notifier).state =
                    filter.copyWith(type: 'adjustment');
              }),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تم'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final isDark = AppTheme.isDark(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor,
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : null,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textColor(context),
      ),
    );
  }
}

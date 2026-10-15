// lib/features/warehouses/presentation/screens/stock_count_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/providers/warehouses_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class StockCountScreen extends ConsumerStatefulWidget {
  final String warehouseId;

  const StockCountScreen({super.key, required this.warehouseId});

  @override
  ConsumerState<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends ConsumerState<StockCountScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(List stocks) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'حفظ الجرد',
      message: 'سيتم تسوية الفروقات تلقائياً. هل أنت متأكد؟',
      confirmText: 'حفظ',
    );

    if (!confirm) return;

    setState(() => _isSaving = true);

    final actualQuantities = <String, double>{};
    for (final stock in stocks) {
      final controller = _controllers[stock.productId];
      if (controller != null && controller.text.isNotEmpty) {
        actualQuantities[stock.productId] =
            Helpers.parseDouble(controller.text);
      }
    }

    final success =
        await ref.read(warehousesControllerProvider.notifier).saveStockCount(
              warehouseId: widget.warehouseId,
              actualQuantities: actualQuantities,
              note: 'جرد - ${Helpers.today()}',
            );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Helpers.showSuccess(context, 'تم حفظ الجرد');
      context.go('/warehouses/${widget.warehouseId}');
    } else {
      Helpers.showError(context, 'فشل الحفظ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockByWarehouseProvider(widget.warehouseId));
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'جرد المخزن',
      ),
      body: stockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'خطأ: $e',
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
        ),
        data: (stocks) {
          if (stocks.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد مخزون للجرد',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.warningColor
                    .withValues(alpha: isDark ? 0.15 : 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اكتب الكميات الفعلية. الفروقات هتتسجل تلقائياً كتسويات.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: stocks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final stock = stocks[index];
                    _controllers.putIfAbsent(
                      stock.productId,
                      () => TextEditingController(),
                    );

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151A23) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppTheme.cardShadow(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.productName ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الكمية الحالية: ${stock.quantity.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _controllers[stock.productId],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'الكمية الفعلية',
                              hintText: stock.quantity.toStringAsFixed(0),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151A23) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _save(stocks),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('حفظ الجرد'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

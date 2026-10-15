// lib/features/warehouses/presentation/screens/stock_movement_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/helpers.dart';
import '../../../products/providers/products_provider.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/providers/warehouses_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class StockMovementFormScreen extends ConsumerStatefulWidget {
  final String warehouseId;

  const StockMovementFormScreen({super.key, required this.warehouseId});

  @override
  ConsumerState<StockMovementFormScreen> createState() =>
      _StockMovementFormScreenState();
}

class _StockMovementFormScreenState
    extends ConsumerState<StockMovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  String? _productId;
  String _type = 'purchase_in';
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productId == null) {
      Helpers.showError(context, 'اختر المنتج');
      return;
    }

    setState(() => _isLoading = true);

    final movement = StockMovementModel(
      id: '',
      warehouseId: widget.warehouseId,
      productId: _productId!,
      type: _type,
      quantity: Helpers.parseDouble(_quantityController.text),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final success = await ref
        .read(warehousesControllerProvider.notifier)
        .createMovement(movement);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Helpers.showSuccess(context, 'تم إضافة الحركة');
      context.go('/warehouses/${widget.warehouseId}');
    } else {
      final error = ref.read(warehousesControllerProvider).error;
      Helpers.showError(context, 'فشل الحفظ: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'حركة مخزون جديدة',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'نوع الحركة',
                prefixIcon: Icon(Icons.swap_vert),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'purchase_in',
                  child: Text('إدخال شراء'),
                ),
                DropdownMenuItem(
                  value: 'adjustment',
                  child: Text('تسوية'),
                ),
                DropdownMenuItem(
                  value: 'return_in',
                  child: Text('مرتجع داخل'),
                ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            _buildProductDropdown(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الكمية *',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'الكمية مطلوبة';
                if (Helpers.parseDouble(v) <= 0) {
                  return 'لازم أكبر من صفر';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDropdown() {
    final productsAsync = ref.watch(productsListProvider);

    return productsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (products) => DropdownButtonFormField<String>(
        initialValue: _productId,
        decoration: const InputDecoration(
          labelText: 'المنتج *',
          prefixIcon: Icon(Icons.inventory_2_outlined),
        ),
        items: products
            .map((p) => DropdownMenuItem<String>(
                  value: p.id,
                  child: Text('${p.name} (${p.sku})'),
                ))
            .toList(),
        onChanged: (v) => setState(() => _productId = v),
        isExpanded: true,
      ),
    );
  }
}

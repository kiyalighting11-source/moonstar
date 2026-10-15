// lib/features/maintenance/presentation/widgets/maintenance_part_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../products/providers/products_provider.dart';
import '../../providers/maintenance_provider.dart';

class MaintenancePartForm extends ConsumerStatefulWidget {
  final String ticketId;
  final String? deviceId; // ⭐ جديد

  const MaintenancePartForm({
    super.key,
    required this.ticketId,
    this.deviceId, // ⭐
  });

  @override
  ConsumerState<MaintenancePartForm> createState() =>
      _MaintenancePartFormState();
}

class _MaintenancePartFormState extends ConsumerState<MaintenancePartForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _productId;
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productId == null) {
      Helpers.showError(context, 'اختر القطعة');
      return;
    }

    setState(() => _isSaving = true);

    final success =
        await ref.read(maintenanceControllerProvider.notifier).addPart(
              ticketId: widget.ticketId,
              deviceId: widget.deviceId, // ⭐
              productId: _productId!,
              quantity: Helpers.parseDouble(_quantityController.text),
              unitPrice: Helpers.parseDouble(_priceController.text),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
      Helpers.showSuccess(context, 'تمت إضافة القطعة');
    } else {
      Helpers.showError(context, 'فشل الحفظ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final productsAsync = ref.watch(productsListProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.build_circle,
                    color: AppTheme.infoColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'إضافة قطعة غيار',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Product Dropdown
            productsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
              data: (products) => DropdownButtonFormField<String>(
                initialValue: _productId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'القطعة *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: products
                    .map((p) => DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(
                            '${p.name} (${p.sku})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _productId = v;
                    if (v != null) {
                      final p = products.firstWhere((e) => e.id == v);
                      _priceController.text = p.price.toStringAsFixed(0);
                    }
                  });
                },
                validator: (v) => v == null ? 'اختر القطعة' : null,
              ),
            ),

            const SizedBox(height: 12),

            // Quantity + Price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الكمية *',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final d = Helpers.parseDouble(v);
                      if (d <= 0) return 'لازم أكبر من صفر';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر *',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: 'ج.م',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final d = Helpers.parseDouble(v);
                      if (d < 0) return 'قيمة غير صحيحة';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'مثال: اتغير Power Supply الأصلي',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text(
                  'إضافة',
                  style: TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

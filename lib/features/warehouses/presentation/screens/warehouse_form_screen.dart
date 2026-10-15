// lib/features/warehouses/presentation/screens/warehouse_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/warehouse_model.dart';
import '../../data/providers/warehouses_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class WarehouseFormScreen extends ConsumerStatefulWidget {
  final String? warehouseId;

  const WarehouseFormScreen({super.key, this.warehouseId});

  bool get isEdit => warehouseId != null;

  @override
  ConsumerState<WarehouseFormScreen> createState() =>
      _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends ConsumerState<WarehouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _managerId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadWarehouse();
  }

  Future<void> _loadWarehouse() async {
    setState(() => _isLoading = true);
    try {
      final warehouse = await ref
          .read(warehousesRepositoryProvider)
          .getWarehouseById(widget.warehouseId!);

      if (warehouse == null) {
        if (mounted) {
          Helpers.showError(context, 'المخزن غير موجود');
          context.go('/warehouses');
        }
        return;
      }

      _nameController.text = warehouse.name;
      _locationController.text = warehouse.location ?? '';
      _notesController.text = warehouse.notes ?? '';
      _managerId = warehouse.managerId;
      _isActive = warehouse.isActive;
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final warehouse = WarehouseModel(
      id: widget.warehouseId ?? '',
      name: _nameController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      managerId: _managerId,
      isActive: _isActive,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final controller = ref.read(warehousesControllerProvider.notifier);
    final success = widget.isEdit
        ? await controller.updateWarehouse(warehouse)
        : await controller.createWarehouse(warehouse);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Helpers.showSuccess(
        context,
        widget.isEdit ? 'تم تحديث المخزن' : 'تم إضافة المخزن',
      );
      context.go('/warehouses');
    } else {
      final error = ref.read(warehousesControllerProvider).error;
      Helpers.showError(context, 'فشل الحفظ: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: widget.isEdit ? 'تعديل مخزن' : 'مخزن جديد',
      ),
      body: _isLoading && widget.isEdit
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المخزن *',
                      prefixIcon: Icon(Icons.warehouse_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'الموقع',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text('مخزن نشط'),
                    activeThumbColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
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
                      label: Text(
                        widget.isEdit ? 'تحديث' : 'حفظ',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.go('/warehouses'),
                      child: const Text('إلغاء'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

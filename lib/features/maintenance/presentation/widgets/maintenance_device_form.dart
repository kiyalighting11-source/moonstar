// lib/features/maintenance/presentation/widgets/maintenance_device_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/maintenance_device_model.dart';
import '../../providers/maintenance_provider.dart';
import 'device_picker_sheet.dart';

class MaintenanceDeviceForm extends ConsumerStatefulWidget {
  final String ticketId;
  final String? deviceId;

  const MaintenanceDeviceForm({
    super.key,
    required this.ticketId,
    this.deviceId,
  });

  bool get isEdit => deviceId != null;

  @override
  ConsumerState<MaintenanceDeviceForm> createState() =>
      _MaintenanceDeviceFormState();
}

class _MaintenanceDeviceFormState extends ConsumerState<MaintenanceDeviceForm> {
  final _formKey = GlobalKey<FormState>();
  final _issueController = TextEditingController();
  final _resolutionController = TextEditingController();
  final _serialController = TextEditingController();
  final _deviceDescriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  ProductModel? _pickedProduct;
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadDevice();
  }

  @override
  void dispose() {
    _issueController.dispose();
    _resolutionController.dispose();
    _serialController.dispose();
    _deviceDescriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // =====================================================
  // Load Device (Edit Mode)
  // =====================================================
  Future<void> _loadDevice() async {
    setState(() => _isLoading = true);
    try {
      final ticket = await ref
          .read(maintenanceRepositoryProvider)
          .getTicketById(widget.ticketId);

      if (ticket == null) {
        if (mounted) {
          Helpers.showError(context, 'التذكرة غير موجودة');
          Navigator.pop(context);
        }
        return;
      }

      final device =
          ticket.devices.where((d) => d.id == widget.deviceId).firstOrNull;

      if (device == null) {
        if (mounted) {
          Helpers.showError(context, 'الجهاز غير موجود');
          Navigator.pop(context);
        }
        return;
      }

      // ⭐ نملأ الحقول
      _issueController.text = device.issueDescription;
      _resolutionController.text = device.resolution ?? '';
      _serialController.text = device.serialNumber ?? '';
      _deviceDescriptionController.text = device.deviceDescription ?? '';
      _priceController.text = device.price.toStringAsFixed(0);

      // ⭐ نبني ProductModel مؤقت لو الجهاز مرتبط بمنتج
      if (device.productId != null) {
        _pickedProduct = ProductModel(
          id: device.productId!,
          sku: device.productSku ?? '',
          name: device.productName ?? '',
          price: device.price,
          mainImageUrl: device.productImageUrl,
        );
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =====================================================
  // Save (Add or Update)
  // =====================================================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedProduct == null &&
        _deviceDescriptionController.text.trim().isEmpty) {
      Helpers.showError(
        context,
        'اختر جهاز أو اكتب وصف نصي',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(maintenanceControllerProvider.notifier);
      bool success;

      if (widget.isEdit) {
        // ⭐ تعديل جهاز موجود
        success = await controller.updateDevice(
          MaintenanceDeviceModel(
            id: widget.deviceId!,
            ticketId: widget.ticketId,
            productId: _pickedProduct?.id,
            deviceDescription: _deviceDescriptionController.text.trim().isEmpty
                ? null
                : _deviceDescriptionController.text.trim(),
            serialNumber: _serialController.text.trim().isEmpty
                ? null
                : _serialController.text.trim(),
            issueDescription: _issueController.text.trim(),
            resolution: _resolutionController.text.trim().isEmpty
                ? null
                : _resolutionController.text.trim(),
            price: Helpers.parseDouble(_priceController.text),
          ),
        );
      } else {
        // ⭐ إضافة جهاز جديد
        success = await controller.addDevice(
          ticketId: widget.ticketId,
          productId: _pickedProduct?.id,
          deviceDescription: _deviceDescriptionController.text.trim().isEmpty
              ? null
              : _deviceDescriptionController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty
              ? null
              : _serialController.text.trim(),
          issueDescription: _issueController.text.trim(),
          resolution: _resolutionController.text.trim().isEmpty
              ? null
              : _resolutionController.text.trim(),
          price: Helpers.parseDouble(_priceController.text),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context, true);
        Helpers.showSuccess(
          context,
          widget.isEdit ? 'تم تحديث الجهاز' : 'تمت إضافة الجهاز',
        );
      } else {
        final error = ref.read(maintenanceControllerProvider).error;
        Helpers.showError(context, 'فشل الحفظ: $error');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Helpers.showError(context, 'خطأ: $e');
    }
  }

  // =====================================================
  // Build
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
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
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.isEdit ? Icons.edit : Icons.add_box,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isEdit ? 'تعديل جهاز' : 'إضافة جهاز',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Device Picker
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DevicePickerSheet(
                            onPick: (p) => setState(() {
                              _pickedProduct = p;
                              _priceController.text =
                                  p.price.toStringAsFixed(0);
                            }),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.inventory_2,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _pickedProduct?.name ??
                                      'اختر جهاز من القائمة',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor(context),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      if (_pickedProduct == null) ...[
                        TextFormField(
                          controller: _deviceDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'وصف نصي للجهاز',
                            hintText: 'مثال: تلفزيون سامسونج 55 بوصة',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Serial
                      TextFormField(
                        controller: _serialController,
                        decoration: const InputDecoration(
                          labelText: 'الرقم التسلسلي (اختياري)',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Issue
                      TextFormField(
                        controller: _issueController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'وصف المشكلة *',
                          prefixIcon: Icon(Icons.report_problem_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'وصف المشكلة مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Resolution
                      TextFormField(
                        controller: _resolutionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'اللي اتعمل (اختياري)',
                          hintText: 'مثال: اتغير Power Supply',
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'سعر الجهاز (اختياري)',
                          prefixIcon: Icon(Icons.attach_money),
                          suffixText: 'ج.م',
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
                              : Icon(
                                  widget.isEdit ? Icons.check : Icons.add,
                                ),
                          label: Text(
                            widget.isEdit ? 'تحديث' : 'إضافة',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Cancel
                      SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

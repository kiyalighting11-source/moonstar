// lib/features/maintenance/presentation/screens/maintenance_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../customers/data/providers/customers_provider.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../data/models/maintenance_device_model.dart';
import '../../data/models/maintenance_model.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../providers/maintenance_provider.dart';
import '../widgets/device_picker_sheet.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class MaintenanceFormScreen extends ConsumerStatefulWidget {
  final String? ticketId;

  const MaintenanceFormScreen({super.key, this.ticketId});

  bool get isEdit => ticketId != null;

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _laborCostController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  String? _customerId;
  String? _technicianId;
  String _priority = 'normal';
  String _status = 'new';
  DateTime? _expectedDelivery;

  final List<_TempDevice> _devices = [];

  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadTicket();
    } else {
      _devices.add(_TempDevice());
    }
  }

  @override
  void dispose() {
    _laborCostController.dispose();
    _notesController.dispose();
    for (final d in _devices) {
      d.dispose();
    }
    super.dispose();
  }

  // =====================================================
  // Load Ticket (Edit)
  // =====================================================
  Future<void> _loadTicket() async {
    setState(() => _isLoadingData = true);
    try {
      final ticket = await ref
          .read(maintenanceRepositoryProvider)
          .getTicketById(widget.ticketId!);

      if (ticket == null) {
        if (mounted) {
          Helpers.showError(context, 'التذكرة غير موجودة');
          context.go('/maintenance');
        }
        return;
      }

      _customerId = ticket.customerId;
      _technicianId = ticket.technicianId;
      _priority = ticket.priority;
      _status = ticket.status;
      _expectedDelivery = ticket.expectedDelivery;
      _laborCostController.text = ticket.laborCost.toStringAsFixed(0);
      _notesController.text = ticket.notes ?? '';

      _devices.clear();
      for (final d in ticket.devices) {
        _devices.add(_TempDevice(
          id: d.id,
          productId: d.productId,
          productName: d.productName,
          deviceDescription: d.deviceDescription,
          serialNumber: d.serialNumber,
          issueDescription: d.issueDescription,
          resolution: d.resolution,
          price: d.price,
        ));
      }

      if (_devices.isEmpty) {
        _devices.add(_TempDevice());
      }

      setState(() {});
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // =====================================================
  // Pick Date
  // =====================================================
  Future<void> _pickExpectedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDelivery ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() => _expectedDelivery = picked);
    }
  }

  // =====================================================
  // Add / Remove Device
  // =====================================================
  void _addDevice() {
    setState(() {
      _devices.add(_TempDevice());
    });
  }

  void _removeDevice(int index) {
    if (_devices.length <= 1) {
      Helpers.showWarning(context, 'لازم جهاز واحد على الأقل');
      return;
    }
    setState(() {
      _devices[index].dispose();
      _devices.removeAt(index);
    });
  }

  // =====================================================
  // Save
  // =====================================================
  Future<void> _save() async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔍 _save Called');
    debugPrint('  isEdit: ${widget.isEdit}');
    debugPrint('  customerId: $_customerId');
    debugPrint('  technicianId: $_technicianId');
    debugPrint('  devicesCount: ${_devices.length}');
    debugPrint('═══════════════════════════════════════');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    if (_customerId == null) {
      Helpers.showError(context, 'اختر العميل');
      return;
    }

    // ⭐ نتحقق من الأجهزة
    for (var i = 0; i < _devices.length; i++) {
      final d = _devices[i];
      if (d.issueController.text.trim().isEmpty) {
        Helpers.showError(context, 'اكتب وصف مشكلة الجهاز رقم ${i + 1}');
        return;
      }
      if (d.productId == null &&
          d.deviceDescriptionController.text.trim().isEmpty) {
        Helpers.showError(
          context,
          'اختر جهاز أو اكتب وصف نصي للجهاز رقم ${i + 1}',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(maintenanceRepositoryProvider);

      if (widget.isEdit) {
        // ⭐ تعديل
        final ticket = MaintenanceModel(
          id: widget.ticketId!,
          ticketNumber: '',
          customerId: _customerId!,
          technicianId: _technicianId,
          priority: _priority,
          status: _status,
          laborCost: Helpers.parseDouble(_laborCostController.text),
          expectedDelivery: _expectedDelivery,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        debugPrint('🔍 Updating Ticket: ${ticket.toJson()}');

        final success = await ref
            .read(maintenanceControllerProvider.notifier)
            .updateTicket(ticket);

        if (!mounted) return;

        if (success) {
          await _syncDevices(repo);
          if (!mounted) return;
          Helpers.showSuccess(context, 'تم تحديث التذكرة');
          context.go('/maintenance/${widget.ticketId}');
        } else {
          final error = ref.read(maintenanceControllerProvider).error;
          Helpers.showError(context, 'فشل التحديث: $error');
        }
      } else {
        // ⭐ إنشاء جديد
        final ticket = MaintenanceModel(
          id: '',
          ticketNumber: '',
          customerId: _customerId!,
          technicianId: _technicianId,
          priority: _priority,
          status: _status,
          laborCost: Helpers.parseDouble(_laborCostController.text),
          expectedDelivery: _expectedDelivery,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        debugPrint('═══════════════════════════════════════');
        debugPrint('🔍 Creating Ticket');
        debugPrint('  customerId: ${ticket.customerId}');
        debugPrint('  technicianId: ${ticket.technicianId}');
        debugPrint('  priority: ${ticket.priority}');
        debugPrint('  status: ${ticket.status}');
        debugPrint('  laborCost: ${ticket.laborCost}');
        debugPrint('  expectedDelivery: ${ticket.expectedDelivery}');
        debugPrint('  notes: ${ticket.notes}');
        debugPrint('═══════════════════════════════════════');

        final created = await ref
            .read(maintenanceControllerProvider.notifier)
            .createTicket(ticket);

        debugPrint('🔍 createTicket Result: $created');

        if (!mounted) return;

        if (created != null) {
          // ⭐ إضافة الأجهزة
          for (final d in _devices) {
            debugPrint('🔍 Adding Device:');
            debugPrint('  productId: ${d.productId}');
            debugPrint('  issueDescription: ${d.issueController.text}');
            debugPrint('  price: ${d.priceController.text}');

            await repo.addDevice(
              ticketId: created.id,
              productId: d.productId,
              deviceDescription:
                  d.deviceDescriptionController.text.trim().isEmpty
                      ? null
                      : d.deviceDescriptionController.text.trim(),
              serialNumber: d.serialNumberController.text.trim().isEmpty
                  ? null
                  : d.serialNumberController.text.trim(),
              issueDescription: d.issueController.text.trim(),
              resolution: d.resolutionController.text.trim().isEmpty
                  ? null
                  : d.resolutionController.text.trim(),
              price: Helpers.parseDouble(d.priceController.text),
            );
          }

          await repo.recalculateTicketTotals(created.id);

          if (!mounted) return;
          Helpers.showSuccess(context, 'تم إنشاء التذكرة');
          context.go('/maintenance/${created.id}');
        } else {
          final error = ref.read(maintenanceControllerProvider).error;
          Helpers.showError(context, 'فشل الإنشاء: $error');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ _save Error');
      debugPrint('  error: $e');
      debugPrint('  stack: $stackTrace');
      debugPrint('═══════════════════════════════════════');
      if (!mounted) return;
      Helpers.showError(context, 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncDevices(MaintenanceRepository repo) async {
    final existing = await repo.getTicketDevices(widget.ticketId!);
    final existingIds = existing.map((d) => d.id).toSet();
    final currentIds =
        _devices.where((d) => d.id != null).map((d) => d.id!).toSet();

    for (final oldId in existingIds) {
      if (!currentIds.contains(oldId)) {
        await repo.deleteDevice(oldId, widget.ticketId!);
      }
    }

    for (final d in _devices) {
      if (d.id != null) {
        await repo.updateDevice(
          MaintenanceDeviceModel(
            id: d.id!,
            ticketId: widget.ticketId!,
            productId: d.productId,
            deviceDescription: d.deviceDescriptionController.text.trim().isEmpty
                ? null
                : d.deviceDescriptionController.text.trim(),
            serialNumber: d.serialNumberController.text.trim().isEmpty
                ? null
                : d.serialNumberController.text.trim(),
            issueDescription: d.issueController.text.trim(),
            resolution: d.resolutionController.text.trim().isEmpty
                ? null
                : d.resolutionController.text.trim(),
            price: Helpers.parseDouble(d.priceController.text),
          ),
        );
      } else {
        await repo.addDevice(
          ticketId: widget.ticketId!,
          productId: d.productId,
          deviceDescription: d.deviceDescriptionController.text.trim().isEmpty
              ? null
              : d.deviceDescriptionController.text.trim(),
          serialNumber: d.serialNumberController.text.trim().isEmpty
              ? null
              : d.serialNumberController.text.trim(),
          issueDescription: d.issueController.text.trim(),
          resolution: d.resolutionController.text.trim().isEmpty
              ? null
              : d.resolutionController.text.trim(),
          price: Helpers.parseDouble(d.priceController.text),
        );
      }
    }

    await repo.recalculateTicketTotals(widget.ticketId!);
  }

  // =====================================================
  // Build
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: widget.isEdit ? 'تعديل تذكرة' : 'تذكرة جديدة',
        actions: const [ThemeToggleButton()],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // العميل
                  _sectionTitle(context, 'العميل'),
                  _buildCustomerDropdown(),

                  const SizedBox(height: 24),

                  // الأجهزة
                  Row(
                    children: [
                      _sectionTitle(context, 'الأجهزة'),
                      const Spacer(),
                      if (_devices.length < 10)
                        TextButton.icon(
                          onPressed: _addDevice,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة جهاز'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  ..._buildDevicesList(),

                  const SizedBox(height: 24),

                  // الأولوية
                  _sectionTitle(context, 'الأولوية'),
                  _buildPrioritySelector(),

                  const SizedBox(height: 12),

                  // الحالة (في التعديل بس)
                  if (widget.isEdit) ...[
                    _sectionTitle(context, 'الحالة'),
                    _buildStatusSelector(),
                    const SizedBox(height: 24),
                  ],

                  // الفني
                  _sectionTitle(context, 'الفني المسؤول'),
                  _buildTechnicianDropdown(),

                  const SizedBox(height: 24),

                  // أجرة الصيانة
                  _sectionTitle(context, 'أجرة الصيانة'),
                  TextFormField(
                    controller: _laborCostController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'أجرة الصيانة',
                      prefixIcon: Icon(Icons.build),
                      suffixText: 'ج.م',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final d = double.tryParse(v);
                      if (d == null || d < 0) return 'قيمة غير صحيحة';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // تاريخ التسليم
                  _sectionTitle(context, 'تاريخ التسليم المتوقع'),
                  InkWell(
                    onTap: _pickExpectedDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: Icon(Icons.event),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _expectedDelivery == null
                            ? 'اختر التاريخ (اختياري)'
                            : DateFormat('dd/MM/yyyy', 'ar')
                                .format(_expectedDelivery!),
                        style: TextStyle(
                          color: _expectedDelivery == null
                              ? AppTheme.textSecondaryColor(context)
                              : AppTheme.textColor(context),
                        ),
                      ),
                    ),
                  ),
                  if (_expectedDelivery != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _expectedDelivery = null),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('مسح التاريخ'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ملاحظات
                  _sectionTitle(context, 'ملاحظات'),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // حفظ
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
                        widget.isEdit ? 'تحديث' : 'إنشاء',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.go('/maintenance'),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // =====================================================
  // Devices List
  // =====================================================
  List<Widget> _buildDevicesList() {
    return _devices.asMap().entries.map((entry) {
      final index = entry.key;
      final device = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildDeviceCard(context, device, index),
      );
    }).toList();
  }

  Widget _buildDeviceCard(
    BuildContext context,
    _TempDevice device,
    int index,
  ) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  device.productName ?? 'جهاز ${index + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
              if (_devices.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: () => _removeDevice(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // اختيار الجهاز
          InkWell(
            onTap: () => _pickDevice(device, index),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    device.productId != null
                        ? Icons.inventory_2
                        : Icons.add_box_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      device.productId != null
                          ? (device.productName ?? 'جهاز مختار')
                          : 'اختر جهاز من القائمة',
                      style: TextStyle(
                        fontSize: 13,
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

          const SizedBox(height: 10),

          // وصف نصي (لو مش من القائمة)
          if (device.productId == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                controller: device.deviceDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف نصي للجهاز',
                  hintText: 'مثال: تلفزيون سامسونج 55 بوصة',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
            ),

          // Serial
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: device.serialNumberController,
              decoration: const InputDecoration(
                labelText: 'الرقم التسلسلي (اختياري)',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
          ),

          // وصف المشكلة
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: device.issueController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'وصف المشكلة *',
                prefixIcon: Icon(Icons.report_problem_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'وصف المشكلة مطلوب' : null,
            ),
          ),

          // الحل
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: device.resolutionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'اللي اتعمل / الحل (اختياري)',
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
          ),

          // السعر
          TextFormField(
            controller: device.priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'سعر الجهاز (اختياري)',
              prefixIcon: Icon(Icons.attach_money),
              suffixText: 'ج.م',
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Device Picker
  // =====================================================
  void _pickDevice(_TempDevice device, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DevicePickerSheet(
        onPick: (product) {
          setState(() {
            device.productId = product.id;
            device.productName = product.name;
          });
        },
      ),
    );
  }

  // =====================================================
  // Helpers
  // =====================================================
  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    final customersAsync = ref.watch(customersListProvider);

    return customersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ في تحميل العملاء: $e'),
      data: (customers) => DropdownButtonFormField<String>(
        initialValue: _customerId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'العميل *',
          prefixIcon: Icon(Icons.person),
        ),
        items: customers
            .map((c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text('${c.name} (${c.code})'),
                ))
            .toList(),
        onChanged: (v) => setState(() => _customerId = v),
        validator: (v) => v == null ? 'اختر العميل' : null,
      ),
    );
  }

  Widget _buildTechnicianDropdown() {
    final employeesAsync = ref.watch(employeesListProvider);

    return employeesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ في تحميل الموظفين: $e'),
      data: (employees) {
        final technicians = employees.where((e) => e.isActive).toList();

        return DropdownButtonFormField<String>(
          initialValue: _technicianId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'الفني المسؤول (اختياري)',
            prefixIcon: Icon(Icons.person_pin),
            helperText: 'يمكن تعيينه لاحقاً',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('— بدون —'),
            ),
            ...technicians.map(
              (e) => DropdownMenuItem<String>(
                value: e.id,
                child: Text('${e.fullName} (${e.employeeCode})'),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _technicianId = v),
        );
      },
    );
  }

  Widget _buildPrioritySelector() {
    const priorities = [
      _PriorityOption('low', 'منخفضة', Icons.arrow_downward, Colors.grey),
      _PriorityOption('normal', 'عادية', Icons.remove, AppTheme.infoColor),
      _PriorityOption(
          'high', 'عالية', Icons.arrow_upward, AppTheme.warningColor),
      _PriorityOption(
          'urgent', 'عاجلة', Icons.priority_high, AppTheme.errorColor),
    ];

    return Row(
      children: priorities.map((p) {
        final isSelected = _priority == p.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => setState(() => _priority = p.value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? p.color : p.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected ? p.color : p.color.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      p.icon,
                      color: isSelected ? Colors.white : p.color,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      child: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : p.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelector() {
    const statuses = [
      _StatusOption('new', 'جديدة', Icons.fiber_new, AppTheme.infoColor),
      _StatusOption('waiting_parts', 'انتظار قطع', Icons.hourglass_empty,
          AppTheme.errorColor),
      _StatusOption(
          'ready', 'تمت', Icons.check_circle_outline, Color(0xFF00ACC1)),
      _StatusOption(
          'delivered', 'تم التسليم', Icons.check_circle, AppTheme.successColor),
      _StatusOption('cancelled', 'ملغية', Icons.cancel, Colors.grey),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final isSelected = _status == s.value;
        return GestureDetector(
          onTap: () => setState(() => _status = s.value),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? s.color : s.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? s.color : s.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  s.icon,
                  size: 14,
                  color: isSelected ? Colors.white : s.color,
                ),
                const SizedBox(width: 6),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : s.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =====================================================
// Temp Device (للفورم)
// =====================================================
class _TempDevice {
  final String? id;
  String? productId;
  String? productName;

  final TextEditingController deviceDescriptionController;
  final TextEditingController serialNumberController;
  final TextEditingController issueController;
  final TextEditingController resolutionController;
  final TextEditingController priceController;

  _TempDevice({
    this.id,
    this.productId,
    this.productName,
    String? deviceDescription,
    String? serialNumber,
    String? issueDescription,
    String? resolution,
    double price = 0,
  })  : deviceDescriptionController =
            TextEditingController(text: deviceDescription ?? ''),
        serialNumberController =
            TextEditingController(text: serialNumber ?? ''),
        issueController = TextEditingController(text: issueDescription ?? ''),
        resolutionController = TextEditingController(text: resolution ?? ''),
        priceController = TextEditingController(text: price.toStringAsFixed(0));

  void dispose() {
    deviceDescriptionController.dispose();
    serialNumberController.dispose();
    issueController.dispose();
    resolutionController.dispose();
    priceController.dispose();
  }
}

// =====================================================
// Options
// =====================================================
class _PriorityOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _PriorityOption(this.value, this.label, this.icon, this.color);
}

class _StatusOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatusOption(this.value, this.label, this.icon, this.color);
}

// lib/features/advances/presentation/screens/advance_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../data/models/advance_model.dart';
import '../../providers/advances_provider.dart';

class AdvanceFormScreen extends ConsumerStatefulWidget {
  final String? advanceId;

  const AdvanceFormScreen({super.key, this.advanceId});

  bool get isEdit => advanceId != null;

  @override
  ConsumerState<AdvanceFormScreen> createState() => _AdvanceFormScreenState();
}

class _AdvanceFormScreenState extends ConsumerState<AdvanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  String? _employeeId;
  int _installmentMonths = 1;
  DateTime _advanceDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadAdvance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvance() async {
    setState(() => _isLoadingData = true);

    try {
      final advance = await ref
          .read(advancesRepositoryProvider)
          .getAdvanceById(widget.advanceId!);

      if (advance == null) {
        if (mounted) {
          Helpers.showError(context, 'السلفة غير موجودة');
          context.go('/advances');
        }
        return;
      }

      _employeeId = advance.employeeId;
      _amountController.text = advance.amount.toStringAsFixed(0);
      _reasonController.text = advance.reason ?? '';
      _notesController.text = advance.notes ?? '';
      _installmentMonths = advance.installmentMonths;
      _advanceDate = advance.advanceDate;
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _advanceDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );

    if (picked != null) setState(() => _advanceDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_employeeId == null) {
      Helpers.showError(context, 'اختر الموظف');
      return;
    }

    setState(() => _isLoading = true);

    final advance = AdvanceModel(
      id: widget.advanceId ?? '',
      employeeId: _employeeId!,
      amount: Helpers.parseDouble(_amountController.text),
      advanceDate: _advanceDate,
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      installmentMonths: _installmentMonths,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final controller = ref.read(advancesControllerProvider.notifier);
    final success = widget.isEdit
        ? await controller.updateAdvance(advance)
        : await controller.createAdvance(advance);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Helpers.showSuccess(
        context,
        widget.isEdit ? 'تم تحديث السلفة' : 'تم إضافة السلفة',
      );
      context.go('/advances');
    } else {
      final error = ref.read(advancesControllerProvider).error;
      Helpers.showError(context, 'فشل الحفظ: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: widget.isEdit ? 'تعديل سلفة' : 'سلفة جديدة',
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== الموظف =====
                  _sectionTitle(context, 'الموظف'),
                  _buildEmployeeDropdown(),
                  const SizedBox(height: 20),

                  // ===== المبلغ =====
                  _sectionTitle(context, 'المبلغ'),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ *',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: 'ج.م',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'المبلغ مطلوب';
                      if (Helpers.parseDouble(v) <= 0) {
                        return 'لازم أكبر من صفر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ===== التقسيط =====
                  _sectionTitle(context, 'طريقة الخصم'),
                  _buildInstallmentOptions(),
                  const SizedBox(height: 20),

                  // ===== التاريخ =====
                  _sectionTitle(context, 'التاريخ'),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ السلفة',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy', 'ar').format(_advanceDate),
                        style: TextStyle(color: AppTheme.textColor(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ===== السبب =====
                  _sectionTitle(context, 'السبب (اختياري)'),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'السبب',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== ملاحظات =====
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== الأزرار =====
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
                      label: Text(widget.isEdit ? 'تحديث' : 'حفظ'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.go('/advances'),
                      child: const Text('إلغاء'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
    final employeesAsync = ref.watch(employeesListProvider);

    return employeesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (employees) {
        return DropdownButtonFormField<String>(
          initialValue: _employeeId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'الموظف *',
            prefixIcon: Icon(Icons.person),
          ),
          items: employees
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.id,
                  child: Text(
                    '${e.fullName} (${e.employeeCode})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _employeeId = v),
          validator: (v) => v == null ? 'اختر الموظف' : null,
        );
      },
    );
  }

  Widget _buildInstallmentOptions() {
    return Column(
      children: [
        // خيارات سريعة
        Row(
          children: [
            _installmentChip(context, 1, 'مرة واحدة'),
            const SizedBox(width: 8),
            _installmentChip(context, 2, 'شهرين'),
            const SizedBox(width: 8),
            _installmentChip(context, 3, '3 شهور'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _installmentChip(context, 6, '6 شهور'),
            const SizedBox(width: 8),
            _installmentChip(context, 12, 'سنة'),
          ],
        ),
        const SizedBox(height: 12),
        // عرض القسط
        if (_installmentMonths > 1)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppTheme.infoColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'القسط الشهري: ${_calculateInstallment(context)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _installmentChip(BuildContext context, int months, String label) {
    final isDark = AppTheme.isDark(context);
    final selected = _installmentMonths == months;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _installmentMonths = months),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor
                : (isDark ? const Color(0xFF151A23) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.dividerColor),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : AppTheme.textColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _calculateInstallment(BuildContext context) {
    final amount = Helpers.parseDouble(_amountController.text);
    if (amount <= 0 || _installmentMonths <= 0) return '-';
    return Helpers.formatCurrency(amount / _installmentMonths);
  }
}

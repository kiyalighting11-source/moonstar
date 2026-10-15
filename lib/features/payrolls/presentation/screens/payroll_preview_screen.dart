// lib/features/payrolls/presentation/screens/payroll_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../data/models/payroll_model.dart';
import '../../data/repositories/payrolls_repository.dart';
import '../../providers/payrolls_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class PayrollPreviewScreen extends ConsumerStatefulWidget {
  const PayrollPreviewScreen({super.key});

  @override
  ConsumerState<PayrollPreviewScreen> createState() =>
      _PayrollPreviewScreenState();
}

class _PayrollPreviewScreenState extends ConsumerState<PayrollPreviewScreen> {
  EmployeeModel? _employee;
  DateTime _periodStart = DateTime.now();
  DateTime _periodEnd = DateTime.now();

  double _bonus = 0;
  double _otherDeductions = 0;
  double _lateDeduction = 0;
  double _absenceDeduction = 0;

  PayrollModel? _preview;
  bool _isLoadingPreview = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final (start, end) = PayrollsRepository.currentPeriod();
    _periodStart = start;
    _periodEnd = end;
  }

  Future<void> _generatePreview() async {
    if (_employee == null) {
      Helpers.showError(context, 'اختر الموظف أولاً');
      return;
    }

    setState(() => _isLoadingPreview = true);

    try {
      final label = PayrollsRepository.periodLabel(_periodStart, _periodEnd);

      // ⭐ DEBUG
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔍 generatePayrollPreview');
      debugPrint('  employeeId: ${_employee!.id}');
      debugPrint('  employeeName: ${_employee!.fullName}');
      debugPrint('  periodStart: $_periodStart');
      debugPrint('  periodEnd: $_periodEnd');
      debugPrint('  periodLabel: $label');
      debugPrint('═══════════════════════════════════════');

      final preview =
          await ref.read(payrollsRepositoryProvider).generatePayrollPreview(
                employeeId: _employee!.id,
                employeeName: _employee!.fullName,
                employeeCode: _employee!.employeeCode,
                jobTitle: _employee!.jobTitle,
                basicSalary: _employee!.basicSalary,
                periodStart: _periodStart,
                periodEnd: _periodEnd,
                periodLabel: label,
                bonus: _bonus,
                otherDeductions: _otherDeductions,
                lateDeduction: _lateDeduction,
                absenceDeduction: _absenceDeduction,
              );

      // ⭐ DEBUG النتيجة
      debugPrint('═══════════════════════════════════════');
      debugPrint('📊 PAYROLL PREVIEW RESULT');
      debugPrint('  basicSalary: ${preview.basicSalary}');
      debugPrint('  advancesDeduction: ${preview.advancesDeduction}');
      debugPrint('  advancesDetails count: ${preview.advancesDetails.length}');
      debugPrint('  lateDeduction: ${preview.lateDeduction}');
      debugPrint('  absenceDeduction: ${preview.absenceDeduction}');
      debugPrint('  otherDeductions: ${preview.otherDeductions}');
      debugPrint('  netSalary: ${preview.netSalary}');
      debugPrint('═══════════════════════════════════════');

      setState(() => _preview = preview);
    } catch (e, st) {
      debugPrint('❌ ERROR in _generatePreview: $e');
      debugPrint('📍 stack: $st');
      if (mounted) Helpers.showError(context, 'فشل التوليد: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _savePayroll() async {
    if (_preview == null) return;

    final confirm = await Helpers.confirmDialog(
      context,
      title: 'حفظ كشف الراتب',
      message: 'هل تريد حفظ الكشف؟ يمكنك تأكيد القبض بعد الحفظ.',
      confirmText: 'حفظ',
    );

    if (!confirm) return;

    setState(() => _isSaving = true);

    try {
      final saved = await ref
          .read(payrollsControllerProvider.notifier)
          .savePayroll(_preview!);

      if (!mounted) return;

      if (saved != null) {
        Helpers.showSuccess(context, 'تم حفظ الكشف');
        context.go('/payrolls/${saved.id}');
      } else {
        Helpers.showError(context, 'فشل الحفظ');
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'كشف راتب جديد',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, 'الموظف'),
          _buildEmployeeDropdown(),
          const SizedBox(height: 20),
          _sectionTitle(context, 'الفترة'),
          _buildPeriodPicker(),
          const SizedBox(height: 20),
          _sectionTitle(context, 'الإضافات والخصومات'),
          _buildAdjustments(),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_employee == null || _isLoadingPreview)
                  ? null
                  : _generatePreview,
              icon: _isLoadingPreview
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('توليد الكشف'),
            ),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 24),
            _sectionTitle(context, 'المعاينة'),
            _buildPreview(context, _preview!, isDark),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePayroll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
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
                label: const Text('حفظ الكشف'),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
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
    final async = ref.watch(employeesListProvider);

    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (employees) => DropdownButtonFormField<String>(
        initialValue: _employee?.id,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'الموظف',
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
        onChanged: (id) {
          final emp = employees.where((e) => e.id == id).firstOrNull;
          setState(() {
            _employee = emp;
            _preview = null;
          });
        },
      ),
    );
  }

  Widget _buildPeriodPicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pickDate(isStart: true),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'من',
                prefixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(_periodStart),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => _pickDate(isStart: false),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'إلى',
                prefixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(_periodEnd),
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _periodStart : _periodEnd,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _periodStart = picked;
      } else {
        _periodEnd = picked;
      }
      _preview = null;
    });
  }

  Widget _buildAdjustments() {
    return Column(
      children: [
        _numberField(
          label: 'مكافأة',
          icon: Icons.card_giftcard,
          onChanged: (v) {
            _bonus = v;
            _preview = null;
          },
        ),
        const SizedBox(height: 8),
        _numberField(
          label: 'خصم تأخير',
          icon: Icons.access_time,
          onChanged: (v) {
            _lateDeduction = v;
            _preview = null;
          },
        ),
        const SizedBox(height: 8),
        _numberField(
          label: 'خصم غياب',
          icon: Icons.cancel,
          onChanged: (v) {
            _absenceDeduction = v;
            _preview = null;
          },
        ),
        const SizedBox(height: 8),
        _numberField(
          label: 'خصومات أخرى',
          icon: Icons.money_off,
          onChanged: (v) {
            _otherDeductions = v;
            _preview = null;
          },
        ),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: 'ج.م',
      ),
      onChanged: (v) => onChanged(Helpers.parseDouble(v)),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    PayrollModel p,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                size: 16,
                color: AppTheme.textSecondaryColor(context),
              ),
              const SizedBox(width: 6),
              Text(
                p.periodLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.dividerColor,
          ),
          _previewRow(
            context,
            'الراتب الأساسي',
            Helpers.formatCurrency(p.basicSalary),
          ),
          _previewRow(
            context,
            'الراتب اليومي',
            Helpers.formatCurrency(p.dailyRate),
          ),
          Divider(
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.dividerColor,
          ),
          _previewRow(context, 'أيام الحضور', '${p.presentDays} يوم'),
          if (p.absentDays > 0)
            _previewRow(
              context,
              'أيام الغياب',
              '${p.absentDays} يوم',
              color: AppTheme.errorColor,
            ),
          if (p.totalLateMinutes > 0)
            _previewRow(
              context,
              'إجمالي التأخير',
              Helpers.formatMinutes(p.totalLateMinutes),
              color: AppTheme.warningColor,
            ),
          Divider(
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.dividerColor,
          ),
          if (p.bonus > 0)
            _previewRow(
              context,
              '+ مكافأة',
              Helpers.formatCurrency(p.bonus),
              color: AppTheme.successColor,
            ),
          if (p.advancesDeduction > 0)
            _previewRow(
              context,
              '- سلف',
              Helpers.formatCurrency(p.advancesDeduction),
              color: AppTheme.errorColor,
            ),
          if (p.lateDeduction > 0)
            _previewRow(
              context,
              '- تأخير',
              Helpers.formatCurrency(p.lateDeduction),
              color: AppTheme.errorColor,
            ),
          if (p.absenceDeduction > 0)
            _previewRow(
              context,
              '- غياب',
              Helpers.formatCurrency(p.absenceDeduction),
              color: AppTheme.errorColor,
            ),
          if (p.otherDeductions > 0)
            _previewRow(
              context,
              '- أخرى',
              Helpers.formatCurrency(p.otherDeductions),
              color: AppTheme.errorColor,
            ),
          if (p.advancesDetails.isNotEmpty) ...[
            Divider(
              height: 20,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.dividerColor,
            ),
            Text(
              'تفاصيل السلف:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 6),
            ...p.advancesDetails.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_right,
                      size: 14,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                    Expanded(
                      child: Text(
                        'سلفة ${Helpers.formatDate(DateTime.tryParse(a['date'] ?? ''))} — '
                        'خصم: ${Helpers.formatCurrency((a['deducted'] as num?)?.toDouble() ?? 0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Divider(
            height: 24,
            thickness: 2,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.dividerColor,
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الصافي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                Text(
                  Helpers.formatCurrency(p.netSalary),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

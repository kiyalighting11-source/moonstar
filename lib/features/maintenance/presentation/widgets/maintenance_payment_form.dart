// lib/features/maintenance/presentation/widgets/maintenance_payment_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../providers/maintenance_provider.dart';

class MaintenancePaymentForm extends ConsumerStatefulWidget {
  final String ticketId;
  final double maxAmount;

  const MaintenancePaymentForm({
    super.key,
    required this.ticketId,
    required this.maxAmount,
  });

  @override
  ConsumerState<MaintenancePaymentForm> createState() =>
      _MaintenancePaymentFormState();
}

class _MaintenancePaymentFormState
    extends ConsumerState<MaintenancePaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _method = 'cash';
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.maxAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = Helpers.parseDouble(_amountController.text);
    if (amount <= 0) {
      Helpers.showError(context, 'المبلغ لازم يكون أكبر من صفر');
      return;
    }
    if (amount > widget.maxAmount + 0.01) {
      Helpers.showError(
        context,
        'المبلغ أكبر من المتبقي '
        '(${Helpers.formatCurrency(widget.maxAmount)})',
      );
      return;
    }

    setState(() => _isSaving = true);

    final success =
        await ref.read(maintenanceControllerProvider.notifier).addPayment(
              ticketId: widget.ticketId,
              amount: amount,
              method: _method,
              paymentDate: _paymentDate,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
      Helpers.showSuccess(context, 'تم إضافة الدفعة');
    } else {
      Helpers.showError(context, 'فشل الحفظ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
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
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments,
                    color: AppTheme.successColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'إضافة دفعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // المتبقي
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'المتبقي: ${Helpers.formatCurrency(widget.maxAmount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'المبلغ *',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'ج.م',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'المبلغ مطلوب';
                final d = Helpers.parseDouble(v);
                if (d <= 0) return 'لازم أكبر من صفر';
                if (d > widget.maxAmount + 0.01) return 'أكبر من المتبقي';
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Payment Method
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'طريقة الدفع',
                prefixIcon: Icon(Icons.payment),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'cash',
                  child: Row(
                    children: [
                      Icon(
                        Icons.money,
                        size: 18,
                        color: AppTheme.successColor,
                      ),
                      SizedBox(width: 8),
                      Text('كاش'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'vodafone_cash',
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_android,
                        size: 18,
                        color: Color(0xFFE60000),
                      ),
                      SizedBox(width: 8),
                      Text('فودافون كاش'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'instapay',
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 18,
                        color: Color(0xFF6A1B9A),
                      ),
                      SizedBox(width: 8),
                      Text('إنستاباي'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'cash'),
            ),

            const SizedBox(height: 12),

            // Payment Date
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الدفع',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy', 'ar').format(_paymentDate),
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
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
                  'حفظ الدفعة',
                  style: TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/settings/presentation/screens/payroll_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class PayrollSettingsScreen extends ConsumerStatefulWidget {
  const PayrollSettingsScreen({super.key});

  @override
  ConsumerState<PayrollSettingsScreen> createState() =>
      _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends ConsumerState<PayrollSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startDayController = TextEditingController(text: '5');

  int _startDay = 5;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _startDayController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (settings == null) return;

      _startDay = settings.payrollCycleStartDay;
      _startDayController.text = _startDay.toString();
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final current = await ref.read(settingsRepositoryProvider).getSettings();
      if (current == null) throw Exception('الإعدادات غير موجودة');

      final updated = current.copyWith(
        payrollCycleStartDay: _startDay,
      );

      final success = await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(updated);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Helpers.showSuccess(context, 'تم الحفظ ✅');
      } else {
        Helpers.showError(context, 'فشل الحفظ');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Helpers.showError(context, 'خطأ: $e');
    }
  }

  /// نحسب الفترة الحالية بناءً على اليوم
  String _getCurrentPeriodLabel() {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, _startDay);

    DateTime start, end;
    if (now.day >= _startDay) {
      start = thisMonthStart;
      end = DateTime(now.year, now.month + 1, _startDay - 1);
    } else {
      start = DateTime(now.year, now.month - 1, _startDay);
      end = DateTime(now.year, now.month, _startDay - 1);
    }

    return '${Helpers.formatDate(start)} → ${Helpers.formatDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'إعدادات الرواتب',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== Info =====
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.infoColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.infoColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'دورة الرواتب بتبدأ من يوم معين في الشهر '
                            'وتنتهي اليوم اللي قبله في الشهر اللي بعده.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColor(context),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle(context, '📅 بداية دورة الرواتب'),

                  // ===== Slider =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.isDark(context)
                          ? const Color(0xFF151A23)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.cardShadow(context),
                    ),
                    child: Column(
                      children: [
                        // القيمة الحالية
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'يوم $_startDay',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Slider
                        Slider(
                          value: _startDay.toDouble(),
                          min: 1,
                          max: 28,
                          divisions: 27,
                          label: 'يوم $_startDay',
                          activeColor: AppTheme.primaryColor,
                          onChanged: (v) {
                            setState(() {
                              _startDay = v.round();
                              _startDayController.text = _startDay.toString();
                            });
                          },
                        ),

                        // أرقام سريعة
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [1, 5, 10, 15, 20, 25, 28]
                              .map((day) => GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _startDay = day;
                                        _startDayController.text =
                                            day.toString();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _startDay == day
                                            ? AppTheme.primaryColor
                                            : AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$day',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _startDay == day
                                              ? Colors.white
                                              : AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== المعاينة =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'الفترة الحالية',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getCurrentPeriodLabel(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== حقل يدوي =====
                  _sectionTitle(context, '✏️ أو اكتب اليوم يدوياً'),
                  TextFormField(
                    controller: _startDayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'يوم البداية',
                      prefixIcon: Icon(Icons.calendar_today),
                      helperText: 'من 1 إلى 28',
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 1 && n <= 28) {
                        setState(() => _startDay = n);
                      }
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final n = int.tryParse(v);
                      if (n == null || n < 1 || n > 28) {
                        return 'من 1 إلى 28';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // ===== الحفظ =====
                  SizedBox(
                    height: 52,
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
                          : const Icon(Icons.save),
                      label: const Text(
                        'حفظ',
                        style: TextStyle(fontSize: 16),
                      ),
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
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.textColor(context),
        ),
      ),
    );
  }
}

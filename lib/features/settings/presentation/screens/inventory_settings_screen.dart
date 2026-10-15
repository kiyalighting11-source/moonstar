// lib/features/settings/presentation/screens/inventory_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class InventorySettingsScreen extends ConsumerStatefulWidget {
  const InventorySettingsScreen({super.key});

  @override
  ConsumerState<InventorySettingsScreen> createState() =>
      _InventorySettingsScreenState();
}

class _InventorySettingsScreenState
    extends ConsumerState<InventorySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _thresholdController = TextEditingController(text: '10');

  int _threshold = 10;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (settings == null) return;

      _threshold = settings.lowStockThreshold;
      _thresholdController.text = _threshold.toString();
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
        lowStockThreshold: _threshold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'إعدادات المخزون',
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
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: AppTheme.warningColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'لما كمية المنتج توصل للحد ده أو أقل، '
                            'هيتعلم عليه "مخزون منخفض" ويتظهر في التقارير.',
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

                  _sectionTitle(context, '📦 حد المخزون المنخفض'),

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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.warningColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_threshold وحدة',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Slider(
                          value: _threshold.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: '$_threshold',
                          activeColor: AppTheme.warningColor,
                          onChanged: (v) {
                            setState(() {
                              _threshold = v.round();
                              _thresholdController.text = _threshold.toString();
                            });
                          },
                        ),

                        // أرقام سريعة
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [0, 5, 10, 20, 30, 50]
                              .map((n) => GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _threshold = n;
                                        _thresholdController.text =
                                            n.toString();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _threshold == n
                                            ? AppTheme.warningColor
                                            : AppTheme.warningColor
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$n',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _threshold == n
                                              ? Colors.white
                                              : AppTheme.warningColor,
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

                  // ===== مثال =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.warningColor.withValues(alpha: 0.15),
                          AppTheme.warningColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppTheme.warningColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مثال:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'لو منتج عنده $_threshold قطعة أو أقل، '
                                'هيظهر في "المخزون المنخفض"',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== حقل يدوي =====
                  _sectionTitle(context, '✏️ أو اكتب القيمة يدوياً'),
                  TextFormField(
                    controller: _thresholdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الحد',
                      prefixIcon: Icon(Icons.numbers),
                      helperText: '0 = بدون تنبيه',
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 0) {
                        setState(() => _threshold = n);
                      }
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final n = int.tryParse(v);
                      if (n == null || n < 0) {
                        return 'قيمة غير صحيحة';
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

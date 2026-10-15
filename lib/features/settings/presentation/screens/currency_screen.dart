// lib/features/settings/presentation/screens/currency_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class CurrencyScreen extends ConsumerStatefulWidget {
  const CurrencyScreen({super.key});

  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currencyCodeController = TextEditingController();
  final _currencySymbolController = TextEditingController();
  final _taxRateController = TextEditingController(text: '0');
  final _invoicePrefixController = TextEditingController(text: 'INV');

  bool _isLoading = true;
  bool _isSaving = false;

  static const List<Map<String, String>> _suggestedCurrencies = [
    {'code': 'EGP', 'symbol': 'ج.م', 'name': 'جنيه مصري'},
    {'code': 'USD', 'symbol': '\$', 'name': 'دولار أمريكي'},
    {'code': 'EUR', 'symbol': '€', 'name': 'يورو'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'ريال سعودي'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'درهم إماراتي'},
    {'code': 'KWD', 'symbol': 'د.ك', 'name': 'دينار كويتي'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _currencyCodeController.dispose();
    _currencySymbolController.dispose();
    _taxRateController.dispose();
    _invoicePrefixController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (settings == null) return;

      _currencyCodeController.text = settings.currencyCode;
      _currencySymbolController.text = settings.currencySymbol;
      _taxRateController.text = settings.taxRate.toString();
      _invoicePrefixController.text = settings.invoicePrefix;
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectCurrency(String code, String symbol) {
    setState(() {
      _currencyCodeController.text = code;
      _currencySymbolController.text = symbol;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final current = await ref.read(settingsRepositoryProvider).getSettings();
      if (current == null) throw Exception('الإعدادات غير موجودة');

      final updated = current.copyWith(
        currencyCode: _currencyCodeController.text.trim().toUpperCase(),
        currencySymbol: _currencySymbolController.text.trim(),
        taxRate: Helpers.parseDouble(_taxRateController.text),
        invoicePrefix: _invoicePrefixController.text.trim().toUpperCase(),
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
        title: 'العملة والضرائب',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== العملة =====
                  _sectionTitle(context, '💰 العملة'),

                  TextFormField(
                    controller: _currencyCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'كود العملة',
                      prefixIcon: Icon(Icons.code),
                      hintText: 'EGP',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'مطلوب';
                      }
                      if (v.trim().length < 2) {
                        return 'كود قصير جداً';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currencySymbolController,
                    decoration: const InputDecoration(
                      labelText: 'رمز العملة',
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'ج.م',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),

                  const SizedBox(height: 16),

                  // ===== العملات المقترحة =====
                  Text(
                    'اختيار سريع:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedCurrencies.map((c) {
                      final selected =
                          _currencyCodeController.text == c['code'];
                      return GestureDetector(
                        onTap: () => _selectCurrency(c['code']!, c['symbol']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primaryColor
                                : (AppTheme.isDark(context)
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : AppTheme.dividerColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c['symbol']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textColor(context),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c['name']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ===== الضريبة =====
                  _sectionTitle(context, '📊 الضريبة الافتراضية'),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'النسبة دي هتتطبق تلقائياً على الفواتير الجديدة. '
                            'تقدر تعدلها لكل فاتورة.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _taxRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'نسبة الضريبة',
                      prefixIcon: Icon(Icons.percent),
                      suffixText: '%',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final d = double.tryParse(v);
                      if (d == null || d < 0) return 'قيمة غير صحيحة';
                      if (d > 100) return 'لازم أقل من 100%';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ===== بادئة الفاتورة =====
                  _sectionTitle(context, '🧾 بادئة رقم الفاتورة'),

                  TextFormField(
                    controller: _invoicePrefixController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'البادئة',
                      prefixIcon: Icon(Icons.tag),
                      hintText: 'INV',
                      helperText: 'مثال: INV-2026-0001',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
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

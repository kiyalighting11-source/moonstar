// lib/features/settings/presentation/screens/location_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '50');

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  double? _currentLat;
  double? _currentLng;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (settings == null) return;

      if (settings.companyLat != null) {
        _latController.text = settings.companyLat!.toStringAsFixed(6);
      }
      if (settings.companyLng != null) {
        _lngController.text = settings.companyLng!.toStringAsFixed(6);
      }
      _radiusController.text = settings.attendanceRadiusMeters.toString();
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ⭐ نجيب الموقع الحالي من GPS
  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        setState(() {
          _locationError = 'فشل قراءة الموقع. تأكد إن GPS مفعّل.';
        });
        return;
      }

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      if (mounted) {
        Helpers.showSuccess(context, 'تم قراءة الموقع الحالي ✅');
      }
    } catch (e) {
      setState(() => _locationError = 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    final radius = int.tryParse(_radiusController.text);

    if (lat == null || lng == null || radius == null) {
      Helpers.showError(context, 'قيم غير صحيحة');
      return;
    }

    if (lat < -90 || lat > 90) {
      Helpers.showError(context, 'خط العرض لازم بين -90 و 90');
      return;
    }
    if (lng < -180 || lng > 180) {
      Helpers.showError(context, 'خط الطول لازم بين -180 و 180');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await ref
          .read(settingsControllerProvider.notifier)
          .updateCompanyLocation(
            lat: lat,
            lng: lng,
            radius: radius,
          );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Helpers.showSuccess(context, 'تم حفظ موقع الشركة ✅');
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
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'موقع الشركة',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== Info Card =====
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
                            'الموظفين هيسجلوا حضور بس في نطاق معين من موقع الشركة. '
                            'تأكد إن الإحداثيات صحيحة.',
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

                  // ===== زرار "احصل على موقعي" =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151A23) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.cardShadow(context),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 48,
                          color: AppTheme.primaryColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اختار موقع الشركة من مكانك الحالي',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isFetchingLocation
                                ? null
                                : _fetchCurrentLocation,
                            icon: _isFetchingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Icon(Icons.gps_fixed),
                            label: Text(
                              _isFetchingLocation
                                  ? 'جاري القراءة...'
                                  : 'احصل على موقعي الحالي',
                            ),
                          ),
                        ),
                        if (_currentLat != null && _currentLng != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'الموقع الحالي: '
                            '${_currentLat!.toStringAsFixed(6)}, '
                            '${_currentLng!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.successColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_locationError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ===== الإحداثيات يدوياً =====
                  _sectionTitle(context, '📍 الإحداثيات'),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'خط العرض',
                            prefixIcon: Icon(Icons.north, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'مطلوب';
                            }
                            final d = double.tryParse(v);
                            if (d == null || d < -90 || d > 90) {
                              return 'قيمة غير صحيحة';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'خط الطول',
                            prefixIcon: Icon(Icons.east, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'مطلوب';
                            }
                            final d = double.tryParse(v);
                            if (d == null || d < -180 || d > 180) {
                              return 'قيمة غير صحيحة';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===== نطاق الحضور =====
                  _sectionTitle(context, '📏 نطاق الحضور'),
                  TextFormField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'النطاق المسموح من الشركة',
                      prefixIcon: Icon(Icons.radar),
                      suffixText: 'متر',
                      helperText: 'الموظف لازم يكون في النطاق ده',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final n = int.tryParse(v);
                      if (n == null || n < 10) {
                        return 'لازم 10 متر على الأقل';
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

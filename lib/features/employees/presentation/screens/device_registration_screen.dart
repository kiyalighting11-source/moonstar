// lib/features/employees/presentation/screens/device_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/device_service.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/employee_model.dart';
import '../../data/providers/employees_provider.dart';

class DeviceRegistrationScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const DeviceRegistrationScreen({
    super.key,
    required this.employeeId,
  });

  @override
  ConsumerState<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState
    extends ConsumerState<DeviceRegistrationScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  String? _deviceId;
  String? _deviceName;
  String? _platform;
  double? _lat;
  double? _lng;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  Future<void> _loadDeviceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deviceInfo = await DeviceService.getDeviceInfo();
      _deviceId = deviceInfo['device_id'] as String?;
      _deviceName =
          '${deviceInfo['brand'] ?? ''} ${deviceInfo['model'] ?? ''}'.trim();
      _platform = deviceInfo['platform'] as String?;

      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        _lat = position.latitude;
        _lng = position.longitude;
      }
    } catch (e) {
      _error = 'فشل قراءة بيانات الجهاز: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDevice(EmployeeModel employee) async {
    if (_deviceId == null || _deviceId!.isEmpty) {
      Helpers.showError(context, 'فشل قراءة معرّف الجهاز');
      return;
    }

    final confirm = await Helpers.confirmDialog(
      context,
      title: 'تأكيد تسجيل الجهاز',
      message: 'هل تريد تسجيل الجهاز ده للموظف "${employee.fullName}"؟\n\n'
          'بعد التسجيل، الموظف هيسجل حضوره من الجهاز ده بس.',
      confirmText: 'تسجيل',
    );

    if (!confirm) return;

    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from(AppConstants.employeesTable).update({
        'device_id': _deviceId,
        'device_registered_at': DateTime.now().toIso8601String(),
        'device_registered_by': userId,
      }).eq('id', employee.id);

      ref.invalidate(employeeByIdProvider(employee.id));
      ref.invalidate(employeesListProvider);
      ref.invalidate(filteredEmployeesProvider);

      if (!mounted) return;

      Helpers.showSuccess(context, 'تم تسجيل الجهاز بنجاح ✅');
      context.go('/employees/${employee.id}');
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'فشل التسجيل: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeDevice(EmployeeModel employee) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'إلغاء تسجيل الجهاز',
      message: 'هل تريد إلغاء ربط الجهاز عن "${employee.fullName}"؟',
      confirmText: 'إلغاء الربط',
      confirmColor: AppTheme.errorColor,
    );

    if (!confirm) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.from(AppConstants.employeesTable).update({
        'device_id': null,
        'device_registered_at': null,
        'device_registered_by': null,
      }).eq('id', employee.id);

      ref.invalidate(employeeByIdProvider(employee.id));
      ref.invalidate(employeesListProvider);
      ref.invalidate(filteredEmployeesProvider);

      if (!mounted) return;
      Helpers.showSuccess(context, 'تم إلغاء ربط الجهاز');
      context.go('/employees/${employee.id}');
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'فشل الإلغاء: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeAsync = ref.watch(employeeByIdProvider(widget.employeeId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'تسجيل الجهاز',
        actions: [
          ThemeToggleButton(),
        ],
      ),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'حدث خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ),
        data: (employee) {
          if (employee == null) {
            return Center(
              child: Text(
                'الموظف غير موجود',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            );
          }
          return _buildContent(context, employee);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, EmployeeModel employee) {
    final isRegistered =
        employee.deviceId != null && employee.deviceId!.isNotEmpty;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildEmployeeHeader(context, employee),
              const SizedBox(height: 20),
              _buildCurrentStatus(context, employee, isRegistered),
              const SizedBox(height: 20),
              if (_error != null)
                _buildErrorCard(context, _error!)
              else ...[
                _sectionTitle(context, '📱 الجهاز الحالي'),
                const SizedBox(height: 8),
                _buildInfoCard(context, [
                  _infoRow(context, Icons.phone_android, 'المعرّف',
                      _deviceId ?? 'غير معروف',
                      isMonospace: true),
                  _infoRow(
                      context, Icons.smartphone, 'الاسم', _deviceName ?? '-'),
                  _infoRow(context, Icons.android, 'المنصة', _platform ?? '-'),
                ]),
                const SizedBox(height: 20),
                _sectionTitle(context, '📍 الموقع الحالي'),
                const SizedBox(height: 8),
                _buildInfoCard(context, [
                  _infoRow(context, Icons.my_location, 'خط العرض',
                      _lat?.toStringAsFixed(6) ?? 'غير متاح',
                      isMonospace: true),
                  _infoRow(context, Icons.my_location, 'خط الطول',
                      _lng?.toStringAsFixed(6) ?? 'غير متاح',
                      isMonospace: true),
                ]),
              ],
              const SizedBox(height: 24),
              if (!_isLoading && _error == null) ...[
                if (!isRegistered)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _saveDevice(employee),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: const Text(
                        'تسجيل الجهاز ده',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isSaving ? null : () => _removeDevice(employee),
                      icon: const Icon(Icons.delete_outline),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      label: const Text(
                        'إلغاء ربط الجهاز',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: TextButton.icon(
                    onPressed: _loadDeviceData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة قراءة البيانات'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
  }

  Widget _buildEmployeeHeader(BuildContext context, EmployeeModel employee) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            child: Text(
              Helpers.initials(employee.fullName),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  employee.employeeCode,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                if (employee.jobTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    employee.jobTitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(
    BuildContext context,
    EmployeeModel employee,
    bool isRegistered,
  ) {
    final color = isRegistered ? AppTheme.successColor : AppTheme.warningColor;
    final icon = isRegistered ? Icons.verified : Icons.warning_amber;
    final text = isRegistered
        ? 'الجهاز مسجل بالفعل'
        : 'الجهاز غير مسجل — الموظف مش هيعرف يسجل حضور';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (isRegistered && employee.deviceRegisteredAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'اتسجل في: ${Helpers.formatDate(employee.deviceRegisteredAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondaryColor(context)),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor(context),
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

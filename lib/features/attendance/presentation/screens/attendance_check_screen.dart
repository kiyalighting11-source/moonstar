// lib/features/attendance/presentation/screens/attendance_check_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/settings_model.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_helpers.dart';
import '../../../../core/utils/device_service.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../data/models/attendance_model.dart';
import '../../providers/attendance_provider.dart';

class AttendanceCheckScreen extends ConsumerStatefulWidget {
  const AttendanceCheckScreen({super.key});

  @override
  ConsumerState<AttendanceCheckScreen> createState() =>
      _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState extends ConsumerState<AttendanceCheckScreen> {
  // حالة الشاشة
  bool _isLoading = true;
  bool _isSubmitting = false;

  // البيانات المقروءة
  EmployeeModel? _employee;
  SettingsModel? _settings;
  AttendanceModel? _todayAttendance;

  // الجهاز والموقع الحالي
  String? _currentDeviceId;
  double? _currentLat;
  double? _currentLng;
  double? _distanceFromCompany;

  // رسائل الخطأ
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1) المستخدم الحالي + بروفايله
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _error = 'يجب تسجيل الدخول أولاً';
        return;
      }

      // 2) بيانات الموظف
      final employeeRepo = ref.read(employeesRepositoryProvider);
      final allEmployees = await employeeRepo.getAllEmployees();
      final employee = allEmployees
          .where(
            (e) => e.profileId == user.id,
          )
          .firstOrNull;

      if (employee == null) {
        _error = 'لا يوجد ملف موظف مرتبط بحسابك';
        return;
      }
      _employee = employee;

      // 3) الإعدادات
      _settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (_settings == null) {
        _error = 'الإعدادات غير متوفرة';
        return;
      }

      // 4) حضور اليوم (لو موجود)
      final attendanceRepo = ref.read(attendanceRepositoryProvider);
      _todayAttendance = await attendanceRepo.getEmployeeAttendanceForDate(
        employeeId: employee.id,
        date: DateTime.now(),
      );

      // 5) الجهاز الحالي
      _currentDeviceId = await DeviceService.getDeviceId();

      // 6) الموقع الحالي
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        _currentLat = position.latitude;
        _currentLng = position.longitude;

        // نحسب المسافة من الشركة
        _distanceFromCompany = AttendanceHelpers.distanceFromCompany(
          companyLat: _settings!.companyLat,
          companyLng: _settings!.companyLng,
          currentLat: _currentLat!,
          currentLng: _currentLng!,
        );
      }
    } catch (e) {
      _error = 'فشل تحميل البيانات: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =====================================================
  // التحقق قبل التسجيل
  // =====================================================

  String? _validateCheckIn() {
    if (_employee == null) return 'الموظف غير موجود';
    if (_settings == null) return 'الإعدادات غير متوفرة';

    // 1) الجهاز
    if (!_employee!.hasRegisteredDevice) {
      return 'الجهاز مش مسجل. تواصل مع الإدارة لتسجيل جهازك.';
    }

    if (_currentDeviceId == null) {
      return 'فشل قراءة معرّف الجهاز.';
    }

    if (_employee!.deviceId != _currentDeviceId) {
      return 'الجهاز ده مش مطابق للجهاز المسجل. اتصل بالإدارة.';
    }

    // 2) الموقع
    if (_currentLat == null || _currentLng == null) {
      return 'فشل قراءة الموقع. تأكد إن GPS مفعّل.';
    }

    if (_settings!.companyLat == null || _settings!.companyLng == null) {
      return 'موقع الشركة مش مسجل. تواصل مع الإدارة.';
    }

    final isWithin = AttendanceHelpers.isLocationWithinRadius(
      companyLat: _settings!.companyLat,
      companyLng: _settings!.companyLng,
      currentLat: _currentLat!,
      currentLng: _currentLng!,
      radiusMeters: _settings!.attendanceRadiusMeters,
    );

    if (!isWithin) {
      final dist = _distanceFromCompany?.toStringAsFixed(0) ?? '؟';
      return 'إنت بعيد عن الشركة ($dist م). لازم تكون في نطاق '
          '${_settings!.attendanceRadiusMeters} متر.';
    }

    return null;
  }

  // =====================================================
  // Check In
  // =====================================================

  Future<void> _checkIn() async {
    final validationError = _validateCheckIn();
    if (validationError != null) {
      Helpers.showError(context, validationError);
      return;
    }

    final confirm = await Helpers.confirmDialog(
      context,
      title: 'تسجيل الحضور',
      message: 'هل تريد تسجيل حضورك الآن؟',
      confirmText: 'تسجيل',
    );

    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      final attendance =
          await ref.read(attendanceControllerProvider.notifier).selfCheckIn(
                employeeId: _employee!.id,
                deviceId: _currentDeviceId!,
                lat: _currentLat!,
                lng: _currentLng!,
                distance: _distanceFromCompany ?? 0,
              );

      if (!mounted) return;

      if (attendance != null) {
        Helpers.showSuccess(
          context,
          'تم تسجيل حضورك في ${AttendanceHelpers.formatTime(attendance.checkIn)} ✅',
        );
        _todayAttendance = attendance;
        setState(() {});
      } else {
        final error = ref.read(attendanceControllerProvider).error;
        Helpers.showError(context, 'فشل التسجيل: $error');
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // =====================================================
  // Check Out
  // =====================================================

  Future<void> _checkOut() async {
    if (_todayAttendance == null) {
      Helpers.showError(context, 'مفيش حضور مسجل النهاردة');
      return;
    }

    // التحقق من الجهاز والموقع
    final validationError = _validateCheckIn();
    if (validationError != null) {
      Helpers.showError(context, validationError);
      return;
    }

    final confirm = await Helpers.confirmDialog(
      context,
      title: 'تسجيل الانصراف',
      message: 'هل تريد تسجيل انصرافك الآن؟',
      confirmText: 'تسجيل الانصراف',
      confirmColor: AppTheme.warningColor,
    );

    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      final attendance =
          await ref.read(attendanceControllerProvider.notifier).checkOut(
                attendanceId: _todayAttendance!.id,
                employeeId: _employee!.id,
                deviceId: _currentDeviceId!,
                lat: _currentLat!,
                lng: _currentLng!,
                distance: _distanceFromCompany ?? 0,
              );

      if (!mounted) return;

      if (attendance != null) {
        Helpers.showSuccess(
          context,
          'تم تسجيل انصرافك في ${AttendanceHelpers.formatTime(attendance.checkOut)} ✅',
        );
        _todayAttendance = attendance;
        setState(() {});
      } else {
        final error = ref.read(attendanceControllerProvider).error;
        Helpers.showError(context, 'فشل التسجيل: $error');
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'تسجيل الحضور',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isCheckedIn = _todayAttendance?.hasCheckedIn ?? false;
    final isCheckedOut = _todayAttendance?.hasCheckedOut ?? false;
    final isComplete = isCheckedIn && isCheckedOut;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEmployeeCard(),
          const SizedBox(height: 16),
          if (isComplete)
            _buildCompleteStatus()
          else if (isCheckedIn)
            _buildCheckedInStatus()
          else
            _buildNotCheckedInStatus(),
          const SizedBox(height: 20),
          _buildVerificationCard(),
          const SizedBox(height: 24),
          if (!isComplete) ...[
            if (!isCheckedIn)
              _buildCheckInButton()
            else if (!isCheckedOut)
              _buildCheckOutButton(),
          ] else
            _buildGoHomeButton(),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: TextButton.icon(
              onPressed: () => context.go(AppConstants.routeMyAttendance),
              icon: const Icon(Icons.history),
              label: const Text('عرض سجلي الكامل'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              Helpers.initials(_employee!.fullName),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employee!.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _employee!.employeeCode,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                if (_employee!.jobTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _employee!.jobTitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
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

  Widget _buildNotCheckedInStatus() {
    return _statusContainer(
      color: AppTheme.infoColor,
      icon: Icons.login,
      title: 'لسه مسجلتش حضورك',
      subtitle: 'اضغط "تسجيل الحضور" تحت لبدء يومك',
    );
  }

  Widget _buildCheckedInStatus() {
    final checkIn = _todayAttendance!.checkIn;
    final late = _todayAttendance!.lateMinutes;

    return Column(
      children: [
        _statusContainer(
          color: AppTheme.successColor,
          icon: Icons.check_circle,
          title: 'سجلت حضورك ✅',
          subtitle: 'الساعة: ${AttendanceHelpers.formatTime(checkIn)}',
        ),
        if (late > 0) ...[
          const SizedBox(height: 8),
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
                  Icons.access_time,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'متأخر بـ ${AttendanceHelpers.formatMinutes(late)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompleteStatus() {
    final a = _todayAttendance!;
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified,
                color: AppTheme.successColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'خلصت يومك ✅',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statRow('الحضور', AttendanceHelpers.formatTime(a.checkIn)),
          _statRow('الانصراف', AttendanceHelpers.formatTime(a.checkOut)),
          _statRow(
            'ساعات العمل',
            AttendanceHelpers.formatMinutes(a.workedMinutes),
          ),
          if (a.lateMinutes > 0)
            _statRow(
              'التأخير',
              AttendanceHelpers.formatMinutes(a.lateMinutes),
              color: AppTheme.warningColor,
            ),
          if (a.earlyLeaveMinutes > 0)
            _statRow(
              'خروج مبكر',
              AttendanceHelpers.formatMinutes(a.earlyLeaveMinutes),
              color: AppTheme.warningColor,
            ),
        ],
      ),
    );
  }

  Widget _statusContainer({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? color}) {
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔐 التحقق',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          _verificationRow(
            icon: Icons.phone_android,
            label: 'الجهاز',
            ok: _employee?.deviceId == _currentDeviceId,
            detail: _currentDeviceId ?? 'غير متاح',
          ),
          _verificationRow(
            icon: Icons.my_location,
            label: 'الموقع',
            ok: _distanceFromCompany != null &&
                _distanceFromCompany! <=
                    (_settings?.attendanceRadiusMeters ?? 50),
            detail: _distanceFromCompany != null
                ? '${_distanceFromCompany!.toStringAsFixed(0)} متر'
                : 'غير متاح',
          ),
        ],
      ),
    );
  }

  Widget _verificationRow({
    required IconData icon,
    required String label,
    required bool ok,
    required String detail,
  }) {
    final color = ok ? AppTheme.successColor : AppTheme.errorColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondaryColor(context),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
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
              detail,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _checkIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.login, size: 26),
        label: const Text(
          'تسجيل الحضور',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCheckOutButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _checkOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.warningColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.logout, size: 26),
        label: const Text(
          'تسجيل الانصراف',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildGoHomeButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => context.go(AppConstants.routeHome),
        icon: const Icon(Icons.home),
        label: const Text('العودة للرئيسية'),
      ),
    );
  }
}

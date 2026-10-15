// lib/features/attendance/presentation/screens/my_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../data/models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../widgets/attendance_card.dart';

class MyAttendanceScreen extends ConsumerStatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  ConsumerState<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends ConsumerState<MyAttendanceScreen> {
  EmployeeModel? _employee;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _error = 'يجب تسجيل الدخول';
        return;
      }

      final all = await ref.read(employeesRepositoryProvider).getAllEmployees();
      final emp = all.where((e) => e.profileId == user.id).firstOrNull;

      if (emp == null) {
        _error = 'لا يوجد ملف موظف مرتبط بحسابك';
        return;
      }

      _employee = emp;
    } catch (e) {
      _error = 'فشل التحميل: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'سجلي',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadEmployee,
          ),
        ],
      ),
      floatingActionButton: _employee != null
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppConstants.routeAttendanceCheckIn),
              icon: const Icon(Icons.login),
              label: const Text('تسجيل'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : _employee == null
                  ? Center(
                      child: Text(
                        'لا يوجد موظف',
                        style: TextStyle(color: AppTheme.textColor(context)),
                      ),
                    )
                  : _buildContent(context),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmployee,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final attendanceAsync =
        ref.watch(employeeAttendanceProvider(_employee!.id));

    return attendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'خطأ: $e',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _buildEmpty(context);
        }

        final stats = _calculateStats(list);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(employeeAttendanceProvider(_employee!.id));
            await ref.read(employeeAttendanceProvider(_employee!.id).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _buildStatsRow(context, stats),
              const SizedBox(height: 20),
              Text(
                'السجل الكامل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 12),
              ...list.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AttendanceCard(
                    attendance: a,
                    showEmployee: false,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مفيش سجل حضور لسه',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بتسجيل حضورك',
            style: TextStyle(color: AppTheme.textSecondaryColor(context)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go(AppConstants.routeAttendanceCheckIn),
            icon: const Icon(Icons.login),
            label: const Text('تسجيل حضور'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            'حضر',
            '${stats['present']}',
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            'متأخر',
            '${stats['late']}',
            Icons.access_time,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            'غايب',
            '${stats['absent']}',
            Icons.cancel,
            AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats(List<AttendanceModel> list) {
    int present = 0;
    int late = 0;
    int absent = 0;

    for (final a in list) {
      switch (a.status) {
        case 'present':
          present++;
          break;
        case 'late':
        case 'very_late':
          late++;
          break;
        case 'absent':
          absent++;
          break;
      }
    }

    return {'present': present, 'late': late, 'absent': absent};
  }
}

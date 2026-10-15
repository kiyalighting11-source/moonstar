// lib/features/admin/presentation/screens/devices_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../widgets/device_employee_card.dart';

// =====================================================
// Filter
// =====================================================
enum DeviceFilter { all, registered, notRegistered }

final deviceFilterProvider = StateProvider<DeviceFilter>((ref) {
  return DeviceFilter.all;
});

final deviceSearchProvider = StateProvider<String>((ref) => '');

// =====================================================
// Filtered employees
// =====================================================
final filteredDeviceEmployeesProvider =
    FutureProvider.autoDispose<List<EmployeeModel>>((ref) async {
  final repo = ref.watch(employeesRepositoryProvider);
  final all = await repo.getAllEmployees();

  final filter = ref.watch(deviceFilterProvider);
  final search = ref.watch(deviceSearchProvider).trim().toLowerCase();

  var list = all;

  switch (filter) {
    case DeviceFilter.registered:
      list = list.where((e) => e.hasRegisteredDevice).toList();
      break;
    case DeviceFilter.notRegistered:
      list = list.where((e) => !e.hasRegisteredDevice).toList();
      break;
    case DeviceFilter.all:
      break;
  }

  if (search.isNotEmpty) {
    list = list.where((e) {
      return e.fullName.toLowerCase().contains(search) ||
          e.employeeCode.toLowerCase().contains(search) ||
          (e.phone?.toLowerCase().contains(search) ?? false);
    }).toList();
  }

  return list;
});

// =====================================================
// Screen
// =====================================================
class DevicesManagementScreen extends ConsumerStatefulWidget {
  const DevicesManagementScreen({super.key});

  @override
  ConsumerState<DevicesManagementScreen> createState() =>
      _DevicesManagementScreenState();
}

class _DevicesManagementScreenState
    extends ConsumerState<DevicesManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(filteredDeviceEmployeesProvider);
    final allAsync = ref.watch(employeesListProvider);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'إدارة الأجهزة',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(employeesListProvider);
              ref.invalidate(filteredDeviceEmployeesProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ============ إحصائيات سريعة ============
          allAsync.when(
            loading: () => const SizedBox(height: 0),
            error: (_, __) => const SizedBox(height: 0),
            data: (all) {
              final registered = all.where((e) => e.hasRegisteredDevice).length;
              final notRegistered = all.length - registered;

              return Container(
                padding: const EdgeInsets.all(12),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.85),
                child: Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        context,
                        'الكل',
                        '${all.length}',
                        Icons.people,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        context,
                        'مسجل',
                        '$registered',
                        Icons.check_circle,
                        AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        context,
                        'مش مسجل',
                        '$notRegistered',
                        Icons.warning_amber,
                        AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ============ بحث ============
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  ref.read(deviceSearchProvider.notifier).state = v;
                },
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الكود أو الموبايل...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(deviceSearchProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // ============ فلتر ============
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip(context, 'الكل', DeviceFilter.all),
                const SizedBox(width: 8),
                _filterChip(context, 'مسجل', DeviceFilter.registered),
                const SizedBox(width: 8),
                _filterChip(context, 'مش مسجل', DeviceFilter.notRegistered),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ============ القائمة ============
          Expanded(
            child: employeesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'خطأ: $e',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textColor(context)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(filteredDeviceEmployeesProvider),
                      child: const Text('إعادة'),
                    ),
                  ],
                ),
              ),
              data: (employees) {
                if (employees.isEmpty) {
                  return _buildEmpty(context);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(employeesListProvider);
                    await ref.read(filteredDeviceEmployeesProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return DeviceEmployeeCard(
                        employee: employee,
                        onManage: () => _openDeviceScreen(employee),
                        onUnlink: employee.hasRegisteredDevice
                            ? () => _unlinkDevice(employee)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Actions
  // =====================================================

  Future<void> _openDeviceScreen(EmployeeModel employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل جهاز'),
        content: Text(
          'هيتم تسجيل الجهاز الحالي (اللي إنت شغال عليه دلوقتي) '
          'للموظف "${employee.fullName}".\n\n'
          '⚠️ لازم تكون شغال على جهاز الموظف نفسه عشان يتسجل صح.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('فتح الشاشة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    context.go('/employees/${employee.id}/device');
  }

  Future<void> _unlinkDevice(EmployeeModel employee) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'إلغاء ربط الجهاز',
      message: 'هل تريد إلغاء ربط الجهاز عن "${employee.fullName}"؟\n\n'
          'الموظف مش هيعرف يسجل حضور لحد ما يتم ربط جهاز جديد.',
      confirmText: 'إلغاء الربط',
      confirmColor: AppTheme.errorColor,
    );

    if (!confirm) return;

    try {
      await ref.read(employeesRepositoryProvider).clearDevice(employee.id);

      ref.invalidate(employeesListProvider);
      ref.invalidate(filteredDeviceEmployeesProvider);

      if (!mounted) return;
      Helpers.showSuccess(context, 'تم إلغاء ربط الجهاز');
    } catch (e) {
      if (!mounted) return;
      Helpers.showError(context, 'فشل الإلغاء: $e');
    }
  }

  // =====================================================
  // Widgets
  // =====================================================

  Widget _statBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _filterChip(BuildContext context, String label, DeviceFilter filter) {
    final current = ref.watch(deviceFilterProvider);
    final selected = current == filter;
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: () {
        ref.read(deviceFilterProvider.notifier).state = filter;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.dividerColor),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textColor(context),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
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
              Icons.phone_android,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مفيش موظفين مطابقين',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

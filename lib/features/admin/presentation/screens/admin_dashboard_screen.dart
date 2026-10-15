// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_helpers.dart';
import '../../../../core/utils/helpers.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../widgets/modules_grid.dart';
import '../widgets/quick_actions.dart';
import '../widgets/stats_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  EmployeeModel? _currentEmployee;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final all = await ref.read(employeesRepositoryProvider).getAllEmployees();
      final emp = all.where((e) => e.profileId == user.id).firstOrNull;

      if (mounted) {
        setState(() {
          _currentEmployee = emp;
        });
      }
    } catch (_) {
      // تجاهل الخطأ
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppConstants.routeLogin);
      });
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('حدث خطأ: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return _buildNoProfile(context, ref);
        }

        final fullName = profile['full_name'] as String? ?? 'مستخدم';
        final role = profile['roles'];
        final roleCode = role is Map ? (role['code'] as String? ?? '') : '';
        final roleName = AppConstants.roleNamesAr[roleCode] ?? roleCode;

        final isEmployee = AppConstants.hasAttendance(roleCode);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(todayStatsProvider);
              await _loadEmployee();
            },
            child: CustomScrollView(
              slivers: [
                // =====================================================
                // AppBar شفاف مع Gradient
                // =====================================================
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  actions: [
                    // ⭐ زرار تبديل Dark/Light
                    _buildThemeToggle(),
                    if (!isEmployee)
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        tooltip: 'المتجر',
                        onPressed: () => context.go('/products'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'تسجيل الخروج',
                      onPressed: () => _logout(context, ref),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.85),
                            AppTheme.primaryLight.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.25),
                                    child: Text(
                                      Helpers.initials(fullName),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'أهلاً، $fullName',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.25),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            roleName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // =====================================================
                // كارت الحضور (للموظفين بس)
                // =====================================================
                if (isEmployee && _currentEmployee != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildAttendanceCard(),
                    ),
                  ),

                // =====================================================
                // نظرة سريعة
                // =====================================================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'نظرة سريعة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: 20,
                            color: AppTheme.textColor(context),
                          ),
                          tooltip: 'تحديث',
                          onPressed: () =>
                              ref.invalidate(dashboardStatsProvider),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: statsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _buildStatsError(ref, e),
                    data: (stats) => _buildStatsGrid(stats),
                  ),
                ),

                // =====================================================
                // إجراءات سريعة
                // =====================================================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'إجراءات سريعة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: QuickActions(isEmployee: isEmployee),
                ),

                // =====================================================
                // الموديولات
                // =====================================================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Text(
                      'الموديولات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: ModulesGrid(roleCode: roleCode),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // ⭐ زرار تبديل Dark/Light
  // =====================================================
  Widget _buildThemeToggle() {
    final themeMode = ref.watch(themeModeProvider);
    final systemBrightness = MediaQuery.of(context).platformBrightness;

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemBrightness == Brightness.dark);

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(isDark),
        ),
      ),
      tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الغامق',
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggle();
      },
    );
  }

  // =====================================================
  // كارت الحضور
  // =====================================================
  Widget _buildAttendanceCard() {
    final todayAsync = ref.watch(
      employeeTodayAttendanceProvider(_currentEmployee!.id),
    );

    return todayAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (attendance) {
        final hasCheckedIn = attendance?.hasCheckedIn ?? false;
        final hasCheckedOut = attendance?.hasCheckedOut ?? false;

        Color color;
        IconData icon;
        String title;
        String subtitle;

        if (!hasCheckedIn) {
          color = AppTheme.infoColor;
          icon = Icons.login;
          title = 'لسه مسجلتش حضورك';
          subtitle = 'اضغط لتسجيل الحضور';
        } else if (!hasCheckedOut) {
          color = AppTheme.successColor;
          icon = Icons.check_circle;
          title = 'سجلت حضورك ✅';
          subtitle = AttendanceHelpers.formatTime(attendance!.checkIn);
        } else {
          color = AppTheme.primaryColor;
          icon = Icons.verified;
          title = 'خلصت يومك 🎉';
          subtitle =
              'شغلت ${AttendanceHelpers.formatMinutes(attendance!.workedMinutes)}';
        }

        return InkWell(
          onTap: () => context.go(AppConstants.routeAttendanceCheckIn),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // إحصائيات
  // =====================================================
  Widget _buildStatsGrid(dynamic stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.78,
        children: [
          StatsCard(
            title: 'منتجات',
            value: '${stats.productsCount}',
            icon: Icons.inventory_2,
            color: AppTheme.accentColor,
            onTap: () => context.go('/products'),
          ),
          StatsCard(
            title: 'مخازن',
            value: '${stats.warehousesCount}',
            icon: Icons.warehouse,
            color: AppTheme.primaryColor,
            onTap: () => context.go('/warehouses'),
          ),
          StatsCard(
            title: 'عملاء',
            value: '${stats.customersCount}',
            icon: Icons.people_alt,
            color: AppTheme.infoColor,
            onTap: () => context.go('/customers'),
          ),
          StatsCard(
            title: 'فواتير',
            value: '${stats.invoicesCount}',
            icon: Icons.receipt_long,
            color: AppTheme.successColor,
            onTap: () => context.go('/invoices'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsError(WidgetRef ref, Object error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'خطأ في الإحصائيات',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(dashboardStatsProvider),
                  child: const Text('إعادة'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProfile(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'لا يوجد بروفايل مرتبط بحسابك',
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(AppConstants.routeLogin);
                }
              },
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد من تسجيل الخروج؟',
      confirmText: 'خروج',
      confirmColor: AppTheme.errorColor,
    );

    if (!confirm) return;

    await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted) context.go(AppConstants.routeLogin);
  }
}

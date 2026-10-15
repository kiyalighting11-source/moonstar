// lib/features/maintenance/presentation/screens/maintenance_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../widgets/maintenance_card.dart';

class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleCode = ref.watch(currentRoleProvider);
    final canCreate = roleCode == AppConstants.roleAdmin ||
        roleCode == AppConstants.roleManager ||
        roleCode == AppConstants.roleCashier;

    final ticketsAsync = ref.watch(maintenanceListProvider);
    final statsAsync = ref.watch(maintenanceStatsProvider);
    final filter = ref.watch(maintenanceFilterProvider);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'الصيانة',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(maintenanceListProvider);
              ref.invalidate(maintenanceStatsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppConstants.routeAddMaintenance),
              icon: const Icon(Icons.add),
              label: const Text('تذكرة جديدة'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // =====================================================
          // Stats Bar
          // =====================================================
          statsAsync.when(
            loading: () => const SizedBox(height: 0),
            error: (_, __) => const SizedBox(height: 0),
            data: (stats) => _buildStatsBar(context, stats, isDark),
          ),

          // =====================================================
          // Search
          // =====================================================
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
                  ref.read(maintenanceFilterProvider.notifier).state =
                      filter.copyWith(search: v);
                },
                decoration: InputDecoration(
                  hintText: 'ابحث برقم التذكرة أو العميل أو الجهاز...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(maintenanceFilterProvider.notifier).state =
                                filter.copyWith(clearSearch: true);
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

          // =====================================================
          // Status Filters
          // =====================================================
          _buildStatusFilters(context, filter, isDark),

          const SizedBox(height: 8),

          // =====================================================
          // List
          // =====================================================
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildError(context, ref, e),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return _buildEmpty(context, canCreate);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(maintenanceListProvider);
                    ref.invalidate(maintenanceStatsProvider);
                    await ref.read(maintenanceListProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final ticket = tickets[i];
                      return MaintenanceCard(
                        ticket: ticket,
                        onTap: () => context.go(
                          '/maintenance/${ticket.id}',
                        ),
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
  // Stats Bar
  // =====================================================
  Widget _buildStatsBar(
    BuildContext context,
    Map<String, dynamic> stats,
    bool isDark,
  ) {
    final total = stats['total'] as int? ?? 0;
    final inProgress = stats['in_progress'] as int? ?? 0;
    final ready = stats['ready'] as int? ?? 0;
    final delivered = stats['delivered'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _statBox(
              context,
              'الكل',
              '$total',
              Icons.list_alt,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statBox(
              context,
              'قيد العمل',
              '$inProgress',
              Icons.build,
              AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statBox(
              context,
              'جاهزة',
              '$ready',
              Icons.check_circle_outline,
              AppTheme.infoColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statBox(
              context,
              'تم التسليم',
              '$delivered',
              Icons.check_circle,
              AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Status Filters
  // =====================================================
  Widget _buildStatusFilters(
    BuildContext context,
    MaintenanceFilter filter,
    bool isDark,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip(context, 'الكل', null, filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'جديدة', 'new', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'فحص', 'diagnosing', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'إصلاح', 'repairing', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'انتظار قطع', 'waiting_parts', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'جاهزة', 'ready', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'تم التسليم', 'delivered', filter, isDark),
          const SizedBox(width: 8),
          _filterChip(context, 'ملغية', 'cancelled', filter, isDark),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    String? status,
    MaintenanceFilter filter,
    bool isDark,
  ) {
    final selected =
        status == null ? filter.status == null : filter.status == status;

    return GestureDetector(
      onTap: () {
        if (status == null) {
          ref.read(maintenanceFilterProvider.notifier).state =
              filter.copyWith(clearStatus: true);
        } else {
          ref.read(maintenanceFilterProvider.notifier).state =
              filter.copyWith(status: status);
        }
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textColor(context),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Empty
  // =====================================================
  Widget _buildEmpty(BuildContext context, bool canCreate) {
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
              Icons.build_outlined,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مفيش تذاكر صيانة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإنشاء تذكرة جديدة',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          if (canCreate) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go(AppConstants.routeAddMaintenance),
              icon: const Icon(Icons.add),
              label: const Text('تذكرة جديدة'),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // Error
  // =====================================================
  Widget _buildError(BuildContext context, WidgetRef ref, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(maintenanceListProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

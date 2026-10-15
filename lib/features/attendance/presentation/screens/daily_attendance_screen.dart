// lib/features/attendance/presentation/screens/daily_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_stats_model.dart';
import '../../providers/attendance_provider.dart';
import '../widgets/attendance_card.dart';

class DailyAttendanceScreen extends ConsumerStatefulWidget {
  const DailyAttendanceScreen({super.key});

  @override
  ConsumerState<DailyAttendanceScreen> createState() =>
      _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends ConsumerState<DailyAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'حضور اليوم',
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'اختر تاريخ',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateBar(context, isDark),
          if (_isToday) _buildStats(context, isDark),
          Expanded(
            child:
                _isToday ? _buildTodayList(context) : _buildDateList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
      child: Row(
        children: [
          const Icon(Icons.event, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isToday
                  ? 'اليوم — ${DateFormat('EEEE، dd MMM yyyy', 'ar').format(_selectedDate)}'
                  : DateFormat('EEEE، dd MMM yyyy', 'ar').format(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
          if (!_isToday)
            TextButton(
              onPressed: () => setState(() => _selectedDate = DateTime.now()),
              child: const Text('النهاردة'),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, bool isDark) {
    final statsAsync = ref.watch(todayStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(height: 0),
      error: (_, __) => const SizedBox(height: 0),
      data: (stats) => Padding(
        padding: const EdgeInsets.all(12),
        child: _buildStatsGrid(context, stats),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AttendanceStatsModel stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: [
        _statCard(context, 'حضر', stats.presentToday, Icons.check_circle,
            AppTheme.successColor),
        _statCard(context, 'متأخر', stats.lateToday + stats.veryLateToday,
            Icons.access_time, AppTheme.warningColor),
        _statCard(context, 'غايب', stats.absentToday, Icons.cancel,
            AppTheme.errorColor),
        _statCard(context, 'لسه', stats.notCheckedInYet, Icons.hourglass_empty,
            AppTheme.infoColor),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayList(BuildContext context) {
    final async = ref.watch(todayAttendanceProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'خطأ: $e',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
      ),
      data: (list) => _buildList(context, list),
    );
  }

  Widget _buildDateList(BuildContext context) {
    final async = ref.watch(dailyAttendanceProvider(_selectedDate));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'خطأ: $e',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
      ),
      data: (list) => _buildList(context, list),
    );
  }

  Widget _buildList(BuildContext context, List<AttendanceModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 60,
              color: AppTheme.textSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد سجلات',
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_isToday) {
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(todayStatsProvider);
          await ref.read(todayAttendanceProvider.future);
        } else {
          ref.invalidate(dailyAttendanceProvider(_selectedDate));
          await ref.read(dailyAttendanceProvider(_selectedDate).future);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          return AttendanceCard(
            attendance: list[i],
            showEmployee: true,
            onTap: () => context.go('/attendance/${list[i].id}'),
          );
        },
      ),
    );
  }
}

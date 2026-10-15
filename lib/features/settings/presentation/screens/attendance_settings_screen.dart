// lib/features/settings/presentation/screens/attendance_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class AttendanceSettingsScreen extends ConsumerStatefulWidget {
  const AttendanceSettingsScreen({super.key});

  @override
  ConsumerState<AttendanceSettingsScreen> createState() =>
      _AttendanceSettingsScreenState();
}

class _AttendanceSettingsScreenState
    extends ConsumerState<AttendanceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  TimeOfDay _shiftStart = const TimeOfDay(hour: 13, minute: 30);
  TimeOfDay _shiftEnd = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _absenceMark = const TimeOfDay(hour: 14, minute: 30);

  final _graceController = TextEditingController(text: '15');
  final _radiusController = TextEditingController(text: '50');

  int _weekendDay = 0; // 0 = Sunday

  bool _isLoading = true;
  bool _isSaving = false;

  static const List<String> _weekDaysAr = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _graceController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (settings == null) return;

      _shiftStart = _parseTime(settings.shiftStartTime);
      _shiftEnd = _parseTime(settings.shiftEndTime);
      _absenceMark = _parseTime(settings.absenceMarkTime);
      _graceController.text = settings.graceMinutes.toString();
      _radiusController.text = settings.attendanceRadiusMeters.toString();
      _weekendDay = settings.weekendDay;
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TimeOfDay _parseTime(String? time) {
    if (time == null) return const TimeOfDay(hour: 0, minute: 0);
    final parts = time.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 0, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final current = await ref.read(settingsRepositoryProvider).getSettings();
      if (current == null) throw Exception('الإعدادات غير موجودة');

      final updated = current.copyWith(
        shiftStartTime: _formatTime(_shiftStart),
        shiftEndTime: _formatTime(_shiftEnd),
        absenceMarkTime: _formatTime(_absenceMark),
        graceMinutes: Helpers.parseInt(_graceController.text),
        attendanceRadiusMeters: Helpers.parseInt(_radiusController.text),
        weekendDay: _weekendDay,
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
        title: 'مواعيد الشيفت',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== الشيفت =====
                  _sectionTitle(context, '⏰ الشيفت'),

                  _timePickerTile(
                    context,
                    icon: Icons.login,
                    label: 'وقت بداية الشيفت',
                    time: _shiftStart,
                    color: AppTheme.successColor,
                    onTap: () => _pickTime(
                      initial: _shiftStart,
                      onPicked: (t) => setState(() => _shiftStart = t),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _timePickerTile(
                    context,
                    icon: Icons.logout,
                    label: 'وقت نهاية الشيفت',
                    time: _shiftEnd,
                    color: AppTheme.infoColor,
                    onTap: () => _pickTime(
                      initial: _shiftEnd,
                      onPicked: (t) => setState(() => _shiftEnd = t),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _timePickerTile(
                    context,
                    icon: Icons.warning_amber,
                    label: 'وقت تسجيل الغياب',
                    time: _absenceMark,
                    color: AppTheme.errorColor,
                    onTap: () => _pickTime(
                      initial: _absenceMark,
                      onPicked: (t) => setState(() => _absenceMark = t),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== التسامح =====
                  _sectionTitle(context, '⏱️ دقايق التسامح'),
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
                            'لو دخل في نطاق التسامح، مش بيتحسب تأخير',
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
                    controller: _graceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'دقايق التسامح',
                      prefixIcon: Icon(Icons.timer_outlined),
                      suffixText: 'دقيقة',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final n = int.tryParse(v);
                      if (n == null || n < 0) return 'قيمة غير صحيحة';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ===== يوم الإجازة =====
                  _sectionTitle(context, '📅 يوم الإجازة الأسبوعية'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.isDark(context)
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<int>(
                      initialValue: _weekendDay,
                      decoration: const InputDecoration(
                        labelText: 'اليوم',
                        prefixIcon: Icon(Icons.weekend_outlined),
                        border: InputBorder.none,
                      ),
                      items: List.generate(
                        7,
                        (i) => DropdownMenuItem<int>(
                          value: i,
                          child: Text(_weekDaysAr[i]),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) setState(() => _weekendDay = v);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== نطاق الحضور =====
                  _sectionTitle(context, '📍 نطاق الحضور'),
                  TextFormField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'نطاق الحضور من الشركة',
                      prefixIcon: Icon(Icons.radar),
                      suffixText: 'متر',
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

  Widget _timePickerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required TimeOfDay time,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

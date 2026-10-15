// lib/features/payrolls/data/repositories/payrolls_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../advances/data/repositories/advances_repository.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../models/payroll_model.dart';

class PayrollsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AdvancesRepository _advancesRepo = AdvancesRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();

  static const String _selectWithRelations =
      '*, employees!employee_id (full_name, employee_code, job_title), paid_by_profile:profiles!paid_by (full_name)';

  // =====================================================
  // QUERIES
  // =====================================================

  Future<List<PayrollModel>> getAllPayrolls({
    String? employeeId,
    String? periodLabel,
    bool? onlyUnpaid,
  }) async {
    var query =
        _supabase.from(AppConstants.payrollsTable).select(_selectWithRelations);

    if (employeeId != null) query = query.eq('employee_id', employeeId);
    if (periodLabel != null) query = query.eq('period_label', periodLabel);
    if (onlyUnpaid == true) query = query.eq('is_paid', false);

    final data = await query.order('period_start', ascending: false);
    return (data as List).map((e) => PayrollModel.fromJson(e)).toList();
  }

  Future<PayrollModel?> getPayrollById(String id) async {
    final data = await _supabase
        .from(AppConstants.payrollsTable)
        .select(_selectWithRelations)
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return PayrollModel.fromJson(data);
  }

  Future<List<PayrollModel>> getEmployeePayrolls(String employeeId) {
    return getAllPayrolls(employeeId: employeeId);
  }

  // =====================================================
  // GENERATE
  // =====================================================

  /// توليد كشف راتب لموظف لفترة (بدون حفظ — للمعاينة)
  Future<PayrollModel> generatePayrollPreview({
    required String employeeId,
    required String employeeName,
    required String employeeCode,
    required String? jobTitle,
    required double basicSalary,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String periodLabel,
    double lateDeduction = 0,
    double absenceDeduction = 0,
    double bonus = 0,
    double otherDeductions = 0,
  }) async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔍 [Repo] generatePayrollPreview');
    debugPrint('  employeeId: $employeeId');
    debugPrint('  periodStart: $periodStart');
    debugPrint('  periodEnd: $periodEnd');
    debugPrint('═══════════════════════════════════════');

    // 1) إحصائيات الحضور
    final stats = await _attendanceRepo.getEmployeePeriodStats(
      employeeId: employeeId,
      fromDate: periodStart,
      toDate: periodEnd,
    );

    final presentDays = stats['present_days'] as int? ?? 0;
    final absentDays = stats['absent_days'] as int? ?? 0;
    final totalLateMinutes = stats['total_late_minutes'] as int? ?? 0;

    debugPrint('📊 Attendance stats:');
    debugPrint('   presentDays: $presentDays');
    debugPrint('   absentDays: $absentDays');
    debugPrint('   totalLateMinutes: $totalLateMinutes');

    // 2) ⭐ السلف المستحقة
    final pendingAdvances = await _advancesRepo.getPendingAdvances(employeeId);

    debugPrint('═══════════════════════════════════════');
    debugPrint('💰 pendingAdvances for employeeId=$employeeId');
    debugPrint('   count: ${pendingAdvances.length}');
    for (final a in pendingAdvances) {
      debugPrint('   - id=${a.id}');
      debugPrint('     amount=${a.amount}');
      debugPrint('     remainingAmount=${a.remainingAmount}');
      debugPrint('     installmentAmount=${a.installmentAmount}');
      debugPrint('     installmentMonths=${a.installmentMonths}');
      debugPrint('     isFullyPaid=${a.isFullyPaid}');
      debugPrint('     isInstallment=${a.isInstallment}');
    }
    debugPrint('═══════════════════════════════════════');

    double advancesDeduction = 0;
    final advancesDetails = <Map<String, dynamic>>[];

    for (final adv in pendingAdvances) {
      // لو التقسيط → نخصم القسط
      // لو مرة واحدة → نخصم المتبقي (أو المبلغ الكامل لو المتبقي 0)
      final remaining =
          adv.remainingAmount > 0 ? adv.remainingAmount : adv.amount;

      final deduction = adv.isInstallment
          ? (adv.installmentAmount <= remaining
              ? adv.installmentAmount
              : remaining)
          : remaining;

      advancesDeduction += deduction;

      debugPrint(
        '💸 Advance ${adv.id}: installment=${adv.isInstallment}, '
        'installmentAmount=${adv.installmentAmount}, '
        'remaining=$remaining, deduction=$deduction',
      );

      advancesDetails.add({
        'advance_id': adv.id,
        'amount': adv.amount,
        'deducted': deduction,
        'remaining_after': remaining - deduction,
        'date': adv.advanceDate.toIso8601String(),
        'installment_months': adv.installmentMonths,
        'reason': adv.reason,
      });
    }

    debugPrint('═══════════════════════════════════════');
    debugPrint('💰 TOTAL advancesDeduction = $advancesDeduction');
    debugPrint('═══════════════════════════════════════');

    // 3) حساب الراتب
    final dailyRate = basicSalary / 30;
    final gross = basicSalary + bonus;

    final net = gross -
        advancesDeduction -
        lateDeduction -
        absenceDeduction -
        otherDeductions;

    debugPrint('📊 Final calc:');
    debugPrint('   basicSalary: $basicSalary');
    debugPrint('   bonus: $bonus');
    debugPrint('   gross: $gross');
    debugPrint('   advancesDeduction: $advancesDeduction');
    debugPrint('   lateDeduction: $lateDeduction');
    debugPrint('   absenceDeduction: $absenceDeduction');
    debugPrint('   otherDeductions: $otherDeductions');
    debugPrint('   net: $net');
    debugPrint('═══════════════════════════════════════');

    return PayrollModel(
      id: '',
      payrollNumber: '',
      employeeId: employeeId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      periodLabel: periodLabel,
      basicSalary: basicSalary,
      dailyRate: dailyRate,
      grossSalary: gross,
      workingDays: 30,
      presentDays: presentDays,
      absentDays: absentDays,
      totalLateMinutes: totalLateMinutes,
      advancesDeduction: advancesDeduction,
      lateDeduction: lateDeduction,
      absenceDeduction: absenceDeduction,
      otherDeductions: otherDeductions,
      bonus: bonus,
      netSalary: net < 0 ? 0 : net,
      advancesDetails: advancesDetails,
      employeeName: employeeName,
      employeeCode: employeeCode,
      employeeJobTitle: jobTitle,
    );
  }

  /// حفظ كشف الراتب
  Future<PayrollModel> savePayroll(PayrollModel payroll) async {
    final userId = _supabase.auth.currentUser?.id;
    final data = await _supabase
        .from(AppConstants.payrollsTable)
        .insert({
          ...payroll.toJson(),
          'created_by': userId,
        })
        .select(_selectWithRelations)
        .single();

    return PayrollModel.fromJson(data);
  }

  /// تأكيد القبض (خصم السلف تلقائياً)
  Future<PayrollModel> markAsPaid(String payrollId) async {
    final payroll = await getPayrollById(payrollId);
    if (payroll == null) throw Exception('Payroll not found');

    debugPrint('═══════════════════════════════════════');
    debugPrint('💰 markAsPaid → payrollId=$payrollId');
    debugPrint('   advancesDetails count: ${payroll.advancesDetails.length}');
    debugPrint('═══════════════════════════════════════');

    // 1) نخصم السلف
    for (final adv in payroll.advancesDetails) {
      final advanceId = adv['advance_id'] as String?;
      final deducted = (adv['deducted'] as num?)?.toDouble() ?? 0;

      debugPrint(
        '💸 Deducting advance: id=$advanceId, amount=$deducted',
      );

      if (advanceId != null && deducted > 0) {
        await _advancesRepo.deductAdvance(
          advanceId: advanceId,
          amount: deducted,
        );
      }
    }

    // 2) نعلّم الكشف مدفوع
    final userId = _supabase.auth.currentUser?.id;
    final data = await _supabase
        .from(AppConstants.payrollsTable)
        .update({
          'is_paid': true,
          'paid_at': DateTime.now().toIso8601String(),
          'paid_by': userId,
        })
        .eq('id', payrollId)
        .select(_selectWithRelations)
        .single();

    return PayrollModel.fromJson(data);
  }

  /// حذف كشف راتب
  Future<void> deletePayroll(String id) async {
    await _supabase.from(AppConstants.payrollsTable).delete().eq('id', id);
  }

  // =====================================================
  // HELPERS
  // =====================================================

  /// حساب فترة القبض الحالية (من 5 لـ 5)
  static (DateTime start, DateTime end) currentPeriod({int startDay = 5}) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, startDay);

    if (now.day >= startDay) {
      // الفترة: من 5 الشهر الحالي → 4 الشهر الجاي
      final end = DateTime(now.year, now.month + 1, startDay - 1);
      return (thisMonthStart, end);
    } else {
      // الفترة: من 5 الشهر اللي فات → 4 الشهر الحالي
      final start = DateTime(now.year, now.month - 1, startDay);
      final end = DateTime(now.year, now.month, startDay - 1);
      return (start, end);
    }
  }

  /// label الفترة (مثال: "أكتوبر 2026")
  static String periodLabel(DateTime start, DateTime end) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${months[start.month - 1]} ${start.year}';
  }
}

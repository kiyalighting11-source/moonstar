// lib/features/advances/data/repositories/advances_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../../core/constants/app_constants.dart';
import '../models/advance_model.dart';

class AdvancesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _selectWithRelations =
      '*, employees!employee_id (full_name, employee_code), creator:profiles!created_by (full_name)';

  // =====================================================
  // QUERIES
  // =====================================================

  /// كل السلف (للمدير/الأدمن)
  Future<List<AdvanceModel>> getAllAdvances({
    String? employeeId,
    bool? onlyNotDeducted,
  }) async {
    var query =
        _supabase.from(AppConstants.advancesTable).select(_selectWithRelations);

    if (employeeId != null) query = query.eq('employee_id', employeeId);

    if (onlyNotDeducted == true) {
      // ⭐ نستبعد اللي متخصم بالكامل (بس نسيب اللي null أو false)
      query = query.or('is_fully_deducted.is.null,is_fully_deducted.eq.false');
    }

    final data = await query.order('advance_date', ascending: false);
    return (data as List).map((e) => AdvanceModel.fromJson(e)).toList();
  }

  /// سلف موظف معين (للموظف نفسه)
  Future<List<AdvanceModel>> getEmployeeAdvances(String employeeId) {
    return getAllAdvances(employeeId: employeeId);
  }

  /// سلفة واحدة
  Future<AdvanceModel?> getAdvanceById(String id) async {
    final data = await _supabase
        .from(AppConstants.advancesTable)
        .select(_selectWithRelations)
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return AdvanceModel.fromJson(data);
  }

  /// ⭐ السلف المستحقة (اللي لسه متخصمتش) لموظف
  Future<List<AdvanceModel>> getPendingAdvances(String employeeId) async {
    final data = await _supabase
        .from(AppConstants.advancesTable)
        .select(_selectWithRelations)
        .eq('employee_id', employeeId)
        // ⭐ نستبعد بس اللي متخصم بالكامل
        .or('is_fully_deducted.is.null,is_fully_deducted.eq.false')
        .order('advance_date', ascending: true);

    return (data as List).map((e) => AdvanceModel.fromJson(e)).toList();
  }

  /// إجمالي السلف المستحقة لموظف
  Future<double> getTotalPendingAdvances(String employeeId) async {
    final list = await getPendingAdvances(employeeId);
    double total = 0;
    for (final a in list) {
      // ⭐ نستخدم remainingAmount، ولو 0، نرجع لـ amount
      final remaining = a.remainingAmount > 0 ? a.remainingAmount : a.amount;
      total += remaining;
    }
    return total;
  }

  // =====================================================
  // CREATE / UPDATE / DELETE
  // =====================================================

  /// إنشاء سلفة جديدة
  Future<AdvanceModel> createAdvance(AdvanceModel advance) async {
    final userId = _supabase.auth.currentUser?.id;

    // ⭐ نحضّر البيانات مع الحقول الأساسية
    final amount = advance.amount;
    final months =
        advance.installmentMonths > 0 ? advance.installmentMonths : 1;
    final installmentAmount = amount / months;

    final payload = <String, dynamic>{
      ...advance.toJson(),
      'created_by': userId,
      // ⭐ نضمن إن الحقول دي فيها قيم
      'installment_months': months,
      'installment_amount': installmentAmount,
      'remaining_amount': amount,
      'paid_months': 0,
      'is_fully_deducted': false,
      'is_deducted': false,
    };

    final data = await _supabase
        .from(AppConstants.advancesTable)
        .insert(payload)
        .select(_selectWithRelations)
        .single();

    return AdvanceModel.fromJson(data);
  }

  /// تحديث سلفة
  Future<AdvanceModel> updateAdvance(AdvanceModel advance) async {
    // ⭐ نحسب installment_amount لو المبلغ أو المدة اتغيروا
    final amount = advance.amount;
    final months =
        advance.installmentMonths > 0 ? advance.installmentMonths : 1;
    final installmentAmount = amount / months;

    final payload = <String, dynamic>{
      ...advance.toJson(),
      'installment_months': months,
      'installment_amount': installmentAmount,
    };

    final data = await _supabase
        .from(AppConstants.advancesTable)
        .update(payload)
        .eq('id', advance.id)
        .select(_selectWithRelations)
        .single();

    return AdvanceModel.fromJson(data);
  }

  /// حذف سلفة
  Future<void> deleteAdvance(String id) async {
    await _supabase.from(AppConstants.advancesTable).delete().eq('id', id);
  }

  // =====================================================
  // DEDUCTIONS (للرواتب)
  // =====================================================

  /// خصم سلفة (تتنده من Payroll)
  Future<void> deductAdvance({
    required String advanceId,
    required double amount,
  }) async {
    final advance = await getAdvanceById(advanceId);
    if (advance == null) return;

    // ⭐ نحسب remaining_amount بأمان
    final currentRemaining =
        advance.remainingAmount > 0 ? advance.remainingAmount : advance.amount;

    final newRemaining = (currentRemaining - amount).clamp(0, double.infinity);
    final isFullyDeducted = newRemaining <= 0.001;
    final newPaidMonths = advance.paidMonths + 1;

    debugPrint(
      '💸 deductAdvance → id=$advanceId, amount=$amount, '
      'before=$currentRemaining, after=$newRemaining, '
      'fully=$isFullyDeducted',
    );

    await _supabase.from(AppConstants.advancesTable).update({
      'remaining_amount': newRemaining,
      'paid_months': newPaidMonths,
      'is_fully_deducted': isFullyDeducted,
      if (isFullyDeducted) 'is_deducted': true,
      if (isFullyDeducted) 'deducted_at': DateTime.now().toIso8601String(),
      if (isFullyDeducted) 'deducted_by': _supabase.auth.currentUser?.id,
    }).eq('id', advanceId);
  }
}

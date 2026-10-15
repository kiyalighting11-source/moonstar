// lib/features/payrolls/providers/payrolls_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/payroll_model.dart';
import '../data/repositories/payrolls_repository.dart';

// =====================================================
// Repository
// =====================================================
final payrollsRepositoryProvider = Provider<PayrollsRepository>((ref) {
  return PayrollsRepository();
});

// =====================================================
// كل الرواتب (للأدمن بس)
// =====================================================
final allPayrollsProvider =
    FutureProvider.autoDispose<List<PayrollModel>>((ref) async {
  final repo = ref.watch(payrollsRepositoryProvider);
  return await repo.getAllPayrolls();
});

// =====================================================
// رواتب موظف
// =====================================================
final employeePayrollsProvider = FutureProvider.autoDispose
    .family<List<PayrollModel>, String>((ref, employeeId) async {
  final repo = ref.watch(payrollsRepositoryProvider);
  return await repo.getEmployeePayrolls(employeeId);
});

// =====================================================
// كشف واحد
// =====================================================
final payrollByIdProvider =
    FutureProvider.autoDispose.family<PayrollModel?, String>((ref, id) async {
  // ⭐ حماية: لو الـ id مش UUID، ارجع null فوراً
  if (!_isValidUuid(id)) return null;

  final repo = ref.watch(payrollsRepositoryProvider);
  return await repo.getPayrollById(id);
});

// =====================================================
// معاينة كشف الراتب (بدون حفظ)
// =====================================================
class PayrollPreviewParams {
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? jobTitle;
  final double basicSalary;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodLabel;
  final double lateDeduction;
  final double absenceDeduction;
  final double bonus;
  final double otherDeductions;

  const PayrollPreviewParams({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.jobTitle,
    required this.basicSalary,
    required this.periodStart,
    required this.periodEnd,
    required this.periodLabel,
    this.lateDeduction = 0,
    this.absenceDeduction = 0,
    this.bonus = 0,
    this.otherDeductions = 0,
  });
}

final payrollPreviewProvider = FutureProvider.autoDispose
    .family<PayrollModel, PayrollPreviewParams>((ref, params) async {
  final repo = ref.watch(payrollsRepositoryProvider);
  return await repo.generatePayrollPreview(
    employeeId: params.employeeId,
    employeeName: params.employeeName,
    employeeCode: params.employeeCode,
    jobTitle: params.jobTitle,
    basicSalary: params.basicSalary,
    periodStart: params.periodStart,
    periodEnd: params.periodEnd,
    periodLabel: params.periodLabel,
    lateDeduction: params.lateDeduction,
    absenceDeduction: params.absenceDeduction,
    bonus: params.bonus,
    otherDeductions: params.otherDeductions,
  );
});

// =====================================================
// Controller
// =====================================================
class PayrollsController extends StateNotifier<AsyncValue<void>> {
  PayrollsController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final PayrollsRepository _repo;
  final Ref _ref;

  /// حفظ كشف راتب
  Future<PayrollModel?> savePayroll(PayrollModel payroll) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.savePayroll(payroll);
      state = const AsyncValue.data(null);
      _refresh(result.employeeId);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// تأكيد القبض
  Future<PayrollModel?> markAsPaid(String payrollId, String employeeId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.markAsPaid(payrollId);
      state = const AsyncValue.data(null);
      _refresh(employeeId);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// حذف
  Future<bool> deletePayroll(String id, String employeeId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deletePayroll(id);
      state = const AsyncValue.data(null);
      _refresh(employeeId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _refresh(String employeeId) {
    _ref.invalidate(allPayrollsProvider);
    _ref.invalidate(employeePayrollsProvider(employeeId));
  }
}

final payrollsControllerProvider =
    StateNotifierProvider<PayrollsController, AsyncValue<void>>((ref) {
  return PayrollsController(ref.read(payrollsRepositoryProvider), ref);
});

// =====================================================
// UUID validation
// =====================================================
final RegExp _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool _isValidUuid(String s) => _uuidRegex.hasMatch(s);

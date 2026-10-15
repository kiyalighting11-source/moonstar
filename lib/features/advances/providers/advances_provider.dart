// lib/features/advances/providers/advances_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/advance_model.dart';
import '../data/repositories/advances_repository.dart';

// =====================================================
// Repository
// =====================================================
final advancesRepositoryProvider = Provider<AdvancesRepository>((ref) {
  return AdvancesRepository();
});

// =====================================================
// كل السلف (للمدير/الأدمن)
// =====================================================
final allAdvancesProvider =
    FutureProvider.autoDispose<List<AdvanceModel>>((ref) async {
  final repo = ref.watch(advancesRepositoryProvider);
  return await repo.getAllAdvances();
});

// =====================================================
// سلف موظف معين
// =====================================================
final employeeAdvancesProvider = FutureProvider.autoDispose
    .family<List<AdvanceModel>, String>((ref, employeeId) async {
  final repo = ref.watch(advancesRepositoryProvider);
  return await repo.getEmployeeAdvances(employeeId);
});

// =====================================================
// سلف موظف المستحقة
// =====================================================
final pendingAdvancesProvider = FutureProvider.autoDispose
    .family<List<AdvanceModel>, String>((ref, employeeId) async {
  final repo = ref.watch(advancesRepositoryProvider);
  return await repo.getPendingAdvances(employeeId);
});

// =====================================================
// إجمالي السلف المستحقة لموظف
// =====================================================
final totalPendingAdvancesProvider =
    FutureProvider.autoDispose.family<double, String>((ref, employeeId) async {
  final repo = ref.watch(advancesRepositoryProvider);
  return await repo.getTotalPendingAdvances(employeeId);
});

// =====================================================
// سلفة واحدة
// =====================================================
final advanceByIdProvider =
    FutureProvider.autoDispose.family<AdvanceModel?, String>((ref, id) async {
  final repo = ref.watch(advancesRepositoryProvider);
  return await repo.getAdvanceById(id);
});

// =====================================================
// ⭐ سلف الموظف خلال الشهر الحالي
// =====================================================
final currentMonthAdvancesProvider = FutureProvider.autoDispose
    .family<List<AdvanceModel>, String>((ref, employeeId) async {
  final repo = ref.watch(advancesRepositoryProvider);
  final all = await repo.getEmployeeAdvances(employeeId);

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  return all.where((a) {
    return a.advanceDate.isAfter(
          monthStart.subtract(const Duration(seconds: 1)),
        ) &&
        a.advanceDate.isBefore(
          monthEnd.add(const Duration(seconds: 1)),
        );
  }).toList()
    ..sort((a, b) => b.advanceDate.compareTo(a.advanceDate));
});

// =====================================================
// Controller
// =====================================================
class AdvancesController extends StateNotifier<AsyncValue<void>> {
  AdvancesController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final AdvancesRepository _repo;
  final Ref _ref;

  Future<bool> createAdvance(AdvanceModel advance) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createAdvance(advance);
      state = const AsyncValue.data(null);
      _refresh(advance.employeeId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateAdvance(AdvanceModel advance) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateAdvance(advance);
      state = const AsyncValue.data(null);
      _refresh(advance.employeeId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteAdvance(String id, String employeeId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAdvance(id);
      state = const AsyncValue.data(null);
      _refresh(employeeId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _refresh(String employeeId) {
    _ref.invalidate(allAdvancesProvider);
    _ref.invalidate(employeeAdvancesProvider(employeeId));
    _ref.invalidate(pendingAdvancesProvider(employeeId));
    _ref.invalidate(totalPendingAdvancesProvider(employeeId));
    _ref.invalidate(currentMonthAdvancesProvider(employeeId));
  }
}

final advancesControllerProvider =
    StateNotifierProvider<AdvancesController, AsyncValue<void>>((ref) {
  return AdvancesController(ref.read(advancesRepositoryProvider), ref);
});

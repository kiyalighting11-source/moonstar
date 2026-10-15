// lib/features/employees/data/providers/employees_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/department_model.dart'; // ✅
import '../models/employee_model.dart'; // ✅
import '../models/job_title_model.dart'; // ✅
import '../repository/employees_repository.dart'; // ✅

// =====================================================
// Repository
// =====================================================
final employeesRepositoryProvider = Provider<EmployeesRepository>((ref) {
  return EmployeesRepository();
});

// =====================================================
// قائمة الموظفين
// =====================================================
final employeesListProvider =
    FutureProvider.autoDispose<List<EmployeeModel>>((ref) async {
  final repo = ref.watch(employeesRepositoryProvider);
  return await repo.getAllEmployees();
});

// =====================================================
// فلتر الموظفين
// =====================================================
class EmployeesFilter {
  final String? search;
  final String? department;
  final bool onlyActive;

  const EmployeesFilter({
    this.search,
    this.department,
    this.onlyActive = false,
  });

  EmployeesFilter copyWith({
    String? search,
    String? department,
    bool? onlyActive,
    bool clearSearch = false,
    bool clearDepartment = false,
  }) {
    return EmployeesFilter(
      search: clearSearch ? null : (search ?? this.search),
      department: clearDepartment ? null : (department ?? this.department),
      onlyActive: onlyActive ?? this.onlyActive,
    );
  }
}

final employeesFilterProvider =
    StateProvider<EmployeesFilter>((ref) => const EmployeesFilter());

// =====================================================
// الموظفين المفلترين
// =====================================================
final filteredEmployeesProvider =
    FutureProvider.autoDispose<List<EmployeeModel>>((ref) async {
  final repo = ref.watch(employeesRepositoryProvider);
  final filter = ref.watch(employeesFilterProvider);

  return await repo.getAllEmployees(
    onlyActive: filter.onlyActive,
    search: filter.search,
    department: filter.department,
  );
});

// =====================================================
// موظف واحد
// =====================================================
final employeeByIdProvider =
    FutureProvider.autoDispose.family<EmployeeModel?, String>((ref, id) async {
  final repo = ref.watch(employeesRepositoryProvider);
  return await repo.getEmployeeById(id);
});

// =====================================================
// الوظائف
// =====================================================
final jobTitlesProvider =
    FutureProvider.autoDispose<List<JobTitleModel>>((ref) async {
  final repo = ref.watch(employeesRepositoryProvider);
  return await repo.getAllJobTitles();
});

// =====================================================
// الأقسام
// =====================================================
final departmentsProvider =
    FutureProvider.autoDispose<List<DepartmentModel>>((ref) async {
  final repo = ref.watch(employeesRepositoryProvider);
  return await repo.getAllDepartments();
});

// =====================================================
// Controller
// =====================================================
class EmployeesController extends StateNotifier<AsyncValue<void>> {
  EmployeesController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final EmployeesRepository _repo;
  final Ref _ref;

  Future<bool> createEmployee(EmployeeModel employee) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createEmployee(employee);
      state = const AsyncValue.data(null);
      _ref.invalidate(employeesListProvider);
      _ref.invalidate(filteredEmployeesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateEmployee(EmployeeModel employee) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateEmployee(employee);
      state = const AsyncValue.data(null);
      _ref.invalidate(employeesListProvider);
      _ref.invalidate(filteredEmployeesProvider);
      _ref.invalidate(employeeByIdProvider(employee.id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteEmployee(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(employeesListProvider);
      _ref.invalidate(filteredEmployeesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleStatus(String id, bool isActive) async {
    try {
      await _repo.toggleStatus(id, isActive);
      _ref.invalidate(employeesListProvider);
      _ref.invalidate(filteredEmployeesProvider);
      _ref.invalidate(employeeByIdProvider(id));
      return true;
    } catch (e) {
      return false;
    }
  }
}

final employeesControllerProvider =
    StateNotifierProvider<EmployeesController, AsyncValue<void>>((ref) {
  return EmployeesController(ref.read(employeesRepositoryProvider), ref);
});

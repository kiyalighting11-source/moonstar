// lib/features/employees/data/repository/employees_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/department_model.dart';
import '../models/employee_model.dart';
import '../models/job_title_model.dart';

class EmployeesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // EMPLOYEES
  // =====================================================

  Future<List<EmployeeModel>> getAllEmployees({
    bool onlyActive = false,
    String? search,
    String? department,
  }) async {
    var query = _supabase.from(AppConstants.employeesTable).select('*');

    if (onlyActive) query = query.eq('is_active', true);
    if (department != null) query = query.eq('department', department);
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.or(
        'full_name.ilike.%$q%,phone.ilike.%$q%,employee_code.ilike.%$q%,national_id.ilike.%$q%',
      );
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => EmployeeModel.fromJson(e)).toList();
  }

  Future<EmployeeModel?> getEmployeeById(String id) async {
    final data = await _supabase
        .from(AppConstants.employeesTable)
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return EmployeeModel.fromJson(data);
  }

  /// جلب موظف بواسطة الـ profile_id (المستخدم الحالي)
  Future<EmployeeModel?> getEmployeeByProfileId(String profileId) async {
    final data = await _supabase
        .from(AppConstants.employeesTable)
        .select('*')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) return null;
    return EmployeeModel.fromJson(data);
  }

  Future<EmployeeModel> createEmployee(EmployeeModel employee) async {
    final userId = _supabase.auth.currentUser?.id;

    final data = await _supabase
        .from(AppConstants.employeesTable)
        .insert({
          ...employee.toJson(),
          'created_by': userId,
        })
        .select('*')
        .single();

    return EmployeeModel.fromJson(data);
  }

  Future<EmployeeModel> updateEmployee(EmployeeModel employee) async {
    final data = await _supabase
        .from(AppConstants.employeesTable)
        .update(employee.toJson())
        .eq('id', employee.id)
        .select('*')
        .single();

    return EmployeeModel.fromJson(data);
  }

  Future<void> deleteEmployee(String id) async {
    await _supabase
        .from(AppConstants.employeesTable)
        .update({'is_active': false}).eq('id', id);
  }

  Future<void> toggleStatus(String id, bool isActive) async {
    await _supabase
        .from(AppConstants.employeesTable)
        .update({'is_active': isActive}).eq('id', id);
  }

  // =====================================================
  // DEVICE MANAGEMENT
  // =====================================================

  /// تسجيل جهاز للموظف
  Future<void> registerDevice({
    required String employeeId,
    required String deviceId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from(AppConstants.employeesTable).update({
      'device_id': deviceId,
      'device_registered_at': DateTime.now().toIso8601String(),
      'device_registered_by': userId,
    }).eq('id', employeeId);
  }

  /// إلغاء ربط الجهاز
  Future<void> clearDevice(String employeeId) async {
    await _supabase.from(AppConstants.employeesTable).update({
      'device_id': null,
      'device_registered_at': null,
      'device_registered_by': null,
    }).eq('id', employeeId);
  }

  // =====================================================
  // JOB TITLES
  // =====================================================

  Future<List<JobTitleModel>> getAllJobTitles() async {
    final data = await _supabase
        .from('job_titles')
        .select('*')
        .eq('is_active', true)
        .order('name');

    return (data as List).map((e) => JobTitleModel.fromJson(e)).toList();
  }

  Future<JobTitleModel> createJobTitle(JobTitleModel jobTitle) async {
    final data = await _supabase
        .from('job_titles')
        .insert(jobTitle.toJson())
        .select()
        .single();

    return JobTitleModel.fromJson(data);
  }

  // =====================================================
  // DEPARTMENTS
  // =====================================================

  Future<List<DepartmentModel>> getAllDepartments() async {
    final data = await _supabase
        .from('departments')
        .select('*')
        .eq('is_active', true)
        .order('name');

    return (data as List).map((e) => DepartmentModel.fromJson(e)).toList();
  }

  Future<DepartmentModel> createDepartment(DepartmentModel dept) async {
    final data = await _supabase
        .from('departments')
        .insert(dept.toJson())
        .select()
        .single();

    return DepartmentModel.fromJson(data);
  }
}

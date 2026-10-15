// lib/features/employees/presentation/screens/employee_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/employee_model.dart';
import '../../data/providers/employees_provider.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? employeeId;

  const EmployeeFormScreen({super.key, this.employeeId});

  bool get isEdit => employeeId != null;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _salaryController = TextEditingController();
  final _notesController = TextEditingController();

  String? _jobTitle;
  String? _department;
  String? _gender = 'male';
  DateTime? _birthDate;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    setState(() => _isLoading = true);
    try {
      final emp = await ref
          .read(employeesRepositoryProvider)
          .getEmployeeById(widget.employeeId!);

      if (emp == null) {
        if (mounted) {
          Helpers.showError(context, 'الموظف غير موجود');
          context.go('/employees');
        }
        return;
      }

      _nameController.text = emp.fullName;
      _nationalIdController.text = emp.nationalId ?? '';
      _phoneController.text = emp.phone ?? '';
      _emailController.text = emp.email ?? '';
      _addressController.text = emp.address ?? '';
      _salaryController.text = emp.basicSalary.toStringAsFixed(0);
      _notesController.text = emp.notes ?? '';
      _jobTitle = emp.jobTitle;
      _department = emp.department;
      _gender = emp.gender ?? 'male';
      _birthDate = emp.birthDate;
      _isActive = emp.isActive;
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final employee = EmployeeModel(
      id: widget.employeeId ?? '',
      employeeCode: '',
      fullName: _nameController.text.trim(),
      nationalId: _nationalIdController.text.trim().isEmpty
          ? null
          : _nationalIdController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      jobTitle: _jobTitle,
      department: _department,
      basicSalary: Helpers.parseDouble(_salaryController.text),
      hireDate: DateTime.now(),
      isActive: _isActive,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final controller = ref.read(employeesControllerProvider.notifier);
    final success = widget.isEdit
        ? await controller.updateEmployee(employee)
        : await controller.createEmployee(employee);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Helpers.showSuccess(
        context,
        widget.isEdit ? 'تم تحديث الموظف' : 'تم إضافة الموظف',
      );
      context.go('/employees');
    } else {
      final error = ref.read(employeesControllerProvider).error;
      Helpers.showError(context, 'فشل الحفظ: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: widget.isEdit ? 'تعديل موظف' : 'موظف جديد',
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: _isLoading && widget.isEdit
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle(context, 'البيانات الأساسية'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nationalIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الرقم القومي',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'الموبايل',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'الإيميل',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(context, 'بيانات شخصية'),
                  Row(
                    children: [
                      Expanded(child: _genderButton(context, 'ذكر', 'male')),
                      const SizedBox(width: 12),
                      Expanded(child: _genderButton(context, 'أنثى', 'female')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickBirthDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الميلاد',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        _birthDate == null
                            ? 'اختر التاريخ'
                            : DateFormat('dd/MM/yyyy').format(_birthDate!),
                        style: TextStyle(
                          color: _birthDate == null
                              ? AppTheme.textSecondaryColor(context)
                              : AppTheme.textColor(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle(context, 'بيانات الوظيفة'),
                  _buildJobTitleDropdown(),
                  const SizedBox(height: 12),
                  _buildDepartmentDropdown(),
                  const SizedBox(height: 24),
                  _sectionTitle(context, 'الراتب'),
                  TextFormField(
                    controller: _salaryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الراتب الأساسي *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'الراتب مطلوب';
                      if (Helpers.parseDouble(v) <= 0) {
                        return 'لازم أكبر من صفر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text('موظف نشط'),
                    activeThumbColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(widget.isEdit ? 'تحديث' : 'حفظ'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.go('/employees'),
                      child: const Text('إلغاء'),
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
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _genderButton(BuildContext context, String label, String value) {
    final selected = _gender == value;
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(12),
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
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobTitleDropdown() {
    final jobsAsync = ref.watch(jobTitlesProvider);

    return jobsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (jobs) => DropdownButtonFormField<String>(
        initialValue: _jobTitle,
        decoration: const InputDecoration(
          labelText: 'الوظيفة',
          prefixIcon: Icon(Icons.work_outline),
        ),
        items: jobs
            .map((j) => DropdownMenuItem<String>(
                  value: j.name,
                  child: Text(j.name),
                ))
            .toList(),
        onChanged: (v) => setState(() => _jobTitle = v),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    final deptsAsync = ref.watch(departmentsProvider);

    return deptsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (depts) => DropdownButtonFormField<String>(
        initialValue: _department,
        decoration: const InputDecoration(
          labelText: 'القسم',
          prefixIcon: Icon(Icons.business_outlined),
        ),
        items: depts
            .map((d) => DropdownMenuItem<String>(
                  value: d.name,
                  child: Text(d.name),
                ))
            .toList(),
        onChanged: (v) => setState(() => _department = v),
      ),
    );
  }
}

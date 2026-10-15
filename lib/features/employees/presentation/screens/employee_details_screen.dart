// lib/features/employees/presentation/screens/employee_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/employee_model.dart';
import '../../data/providers/employees_provider.dart';

class EmployeeDetailsScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailsScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeByIdProvider(employeeId));
    final isLoggedIn = AuthGuard.isLoggedIn;
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'تفاصيل الموظف',
        actions: [
          const ThemeToggleButton(),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('/employees/edit/$employeeId'),
            ),
        ],
      ),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'حدث خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ),
        data: (employee) {
          if (employee == null) {
            return Center(
              child: Text(
                'الموظف غير موجود',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            );
          }
          return _buildContent(context, employee, isDark);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EmployeeModel employee,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // الهيدر
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151A23) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                child: Text(
                  Helpers.initials(employee.fullName),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                employee.fullName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                employee.employeeCode,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              if (employee.jobTitle != null) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(employee.jobTitle!),
                  backgroundColor: AppTheme.infoColor.withValues(alpha: 0.15),
                  labelStyle: const TextStyle(
                    color: AppTheme.infoColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                ),
              ],
              if (!employee.isActive) ...[
                const SizedBox(height: 8),
                Chip(
                  label: const Text('متوقف'),
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.15),
                  labelStyle: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // الراتب
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.attach_money,
                  color: AppTheme.successColor, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الراتب الأساسي',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  Text(
                    Helpers.formatCurrency(employee.basicSalary),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // بيانات الاتصال
        _section(context, 'بيانات الاتصال', [
          _infoRow(context, Icons.badge_outlined, 'الرقم القومي',
              employee.nationalId),
          _infoRow(context, Icons.phone_outlined, 'الموبايل', employee.phone),
          _infoRow(context, Icons.email_outlined, 'الإيميل', employee.email),
          _infoRow(
              context, Icons.location_on_outlined, 'العنوان', employee.address),
        ]),

        const SizedBox(height: 16),

        // بيانات شخصية
        _section(context, 'بيانات شخصية', [
          _infoRow(
            context,
            Icons.wc_outlined,
            'النوع',
            employee.isMale ? 'ذكر' : 'أنثى',
          ),
          _infoRow(
            context,
            Icons.cake_outlined,
            'تاريخ الميلاد',
            Helpers.formatDate(employee.birthDate),
          ),
        ]),

        const SizedBox(height: 16),

        // بيانات الوظيفة
        _section(context, 'بيانات الوظيفة', [
          _infoRow(context, Icons.work_outline, 'الوظيفة', employee.jobTitle),
          _infoRow(
              context, Icons.business_outlined, 'القسم', employee.department),
          _infoRow(
            context,
            Icons.calendar_today,
            'تاريخ الإضافة',
            Helpers.formatDate(employee.createdAt),
          ),
        ]),

        if (employee.notes != null && employee.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _section(context, 'ملاحظات', [
            Text(
              employee.notes!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textColor(context),
              ),
            ),
          ]),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final isDark = AppTheme.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value,
  ) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondaryColor(context)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

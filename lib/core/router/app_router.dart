// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

// Auth
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';

// Admin Dashboard
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/devices_management_screen.dart';

// 🏠 Landing Pages
import '../../features/landing/presentation/landing_page_screen.dart';
import '../../features/landing/presentation/about_page_screen.dart';
import '../../features/landing/presentation/contact_page_screen.dart';

// 🛒 Shop
import '../../features/products/presentation/public_products_screen.dart';

// Products
import '../../features/products/presentation/products_list_screen.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/product_details_screen.dart';

// Warehouses
import '../../features/warehouses/presentation/screens/warehouses_list_screen.dart';
import '../../features/warehouses/presentation/screens/warehouse_form_screen.dart';
import '../../features/warehouses/presentation/screens/warehouse_details_screen.dart';
import '../../features/warehouses/presentation/screens/stock_movements_screen.dart';
import '../../features/warehouses/presentation/screens/stock_movement_form_screen.dart';
import '../../features/warehouses/presentation/screens/stock_count_screen.dart';

// Customers
import '../../features/customers/presentation/screens/customers_list_screen.dart';
import '../../features/customers/presentation/screens/customer_form_screen.dart';
import '../../features/customers/presentation/screens/customer_details_screen.dart';

// Employees
import '../../features/employees/presentation/screens/employees_list_screen.dart';
import '../../features/employees/presentation/screens/employee_form_screen.dart';
import '../../features/employees/presentation/screens/employee_details_screen.dart';
import '../../features/employees/presentation/screens/device_registration_screen.dart';

// Attendance
import '../../features/attendance/presentation/screens/attendance_check_screen.dart';
import '../../features/attendance/presentation/screens/my_attendance_screen.dart';
import '../../features/attendance/presentation/screens/daily_attendance_screen.dart';
import '../../features/attendance/presentation/screens/attendance_details_screen.dart';

// Advances
import '../../features/advances/presentation/screens/advances_list_screen.dart';
import '../../features/advances/presentation/screens/advance_form_screen.dart';
import '../../features/advances/presentation/screens/my_advances_screen.dart';

// Payrolls
import '../../features/payrolls/presentation/screens/payrolls_list_screen.dart';
import '../../features/payrolls/presentation/screens/payroll_preview_screen.dart';
import '../../features/payrolls/presentation/screens/payroll_details_screen.dart';
import '../../features/payrolls/presentation/screens/my_payrolls_screen.dart';

// Invoices
import '../../features/invoices/presentation/screens/invoices_list_screen.dart';
import '../../features/invoices/presentation/screens/invoice_form_screen.dart';
import '../../features/invoices/presentation/screens/invoice_details_screen.dart';

// Reports
import '../../features/reports/presentation/screens/reports_home_screen.dart';
import '../../features/reports/presentation/screens/sales_report_screen.dart';
import '../../features/reports/presentation/screens/top_products_screen.dart';
import '../../features/reports/presentation/screens/profit_report_screen.dart';

// 🔧 Maintenance
import '../../features/maintenance/presentation/screens/maintenance_list_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_form_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_details_screen.dart';

// Settings
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/company_info_screen.dart';
import '../../features/settings/presentation/screens/attendance_settings_screen.dart';
import '../../features/settings/presentation/screens/location_screen.dart';
import '../../features/settings/presentation/screens/currency_screen.dart';
import '../../features/settings/presentation/screens/payroll_settings_screen.dart';
import '../../features/settings/presentation/screens/inventory_settings_screen.dart';
import '../../features/settings/presentation/screens/job_titles_screen.dart';
import '../../features/settings/presentation/screens/departments_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/system_info_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeLanding,

    routes: [
      // =====================================================
      // 🏠 Landing Page
      // =====================================================
      GoRoute(
        path: AppConstants.routeLanding,
        name: 'landing',
        builder: (context, state) => const LandingPageScreen(),
      ),

      // =====================================================
      // ℹ️ About Page
      // =====================================================
      GoRoute(
        path: AppConstants.routeAbout,
        name: 'about',
        builder: (context, state) => const AboutPageScreen(),
      ),

      // =====================================================
      // 📞 Contact Page
      // =====================================================
      GoRoute(
        path: AppConstants.routeContact,
        name: 'contact',
        builder: (context, state) => const ContactPageScreen(),
      ),

      // =====================================================
      // 🛒 Shop
      // =====================================================
      GoRoute(
        path: AppConstants.routeShop,
        name: 'shop',
        builder: (context, state) => const PublicProductsScreen(),
        routes: [
          GoRoute(
            path: 'product/:id',
            name: 'shop-product',
            builder: (context, state) => ProductDetailsScreen(
              productId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Splash ====================
      GoRoute(
        path: AppConstants.routeSplash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ==================== Login ====================
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ==================== Home (Dashboard) ====================
      GoRoute(
        path: AppConstants.routeHome,
        name: 'home',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // ==================== Admin: Devices ====================
      GoRoute(
        path: AppConstants.routeDevicesManagement,
        name: 'admin-devices',
        builder: (context, state) => const DevicesManagementScreen(),
      ),

      // ==================== Employees ====================
      GoRoute(
        path: AppConstants.routeEmployees,
        name: 'employees',
        builder: (context, state) => const EmployeesListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'employees-add',
            builder: (context, state) => const EmployeeFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'employees-edit',
            builder: (context, state) => EmployeeFormScreen(
              employeeId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id/device',
            name: 'employees-device',
            builder: (context, state) => DeviceRegistrationScreen(
              employeeId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'employees-details',
            builder: (context, state) => EmployeeDetailsScreen(
              employeeId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Attendance ====================
      GoRoute(
        path: AppConstants.routeAttendanceCheckIn,
        name: 'attendance-checkin',
        builder: (context, state) => const AttendanceCheckScreen(),
      ),
      GoRoute(
        path: AppConstants.routeMyAttendance,
        name: 'attendance-me',
        builder: (context, state) => const MyAttendanceScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAttendance,
        name: 'attendance',
        builder: (context, state) => const DailyAttendanceScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'attendance-details',
            builder: (context, state) => AttendanceDetailsScreen(
              attendanceId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Advances ====================
      GoRoute(
        path: AppConstants.routeMyAdvances,
        name: 'advances-me',
        builder: (context, state) => const MyAdvancesScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAddAdvance,
        name: 'advances-add',
        builder: (context, state) => const AdvanceFormScreen(),
      ),
      GoRoute(
        path: '/advances/edit/:id',
        name: 'advances-edit',
        builder: (context, state) => AdvanceFormScreen(
          advanceId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppConstants.routeAdvances,
        name: 'advances',
        builder: (context, state) => const AdvancesListScreen(),
      ),

      // ==================== Payrolls ====================
      GoRoute(
        path: AppConstants.routeMyPayrolls,
        name: 'payrolls-me',
        builder: (context, state) => const MyPayrollsScreen(),
      ),
      GoRoute(
        path: '/payrolls/generate',
        name: 'payrolls-generate',
        builder: (context, state) => const PayrollPreviewScreen(),
      ),
      GoRoute(
        path: AppConstants.routePayrolls,
        name: 'payrolls',
        builder: (context, state) => const PayrollsListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'payrolls-details',
            builder: (context, state) => PayrollDetailsScreen(
              payrollId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Products (Admin) ====================
      GoRoute(
        path: AppConstants.routeProducts,
        name: 'products',
        builder: (context, state) => const ProductsListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'products-add',
            builder: (context, state) => const ProductFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'products-edit',
            builder: (context, state) => ProductFormScreen(
              productId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'products-details',
            builder: (context, state) => ProductDetailsScreen(
              productId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Categories ====================
      GoRoute(
        path: AppConstants.routeCategories,
        name: 'categories',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'التصنيفات',
          icon: Icons.category,
        ),
      ),

      // ==================== Brands ====================
      GoRoute(
        path: AppConstants.routeBrands,
        name: 'brands',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'الماركات',
          icon: Icons.branding_watermark,
        ),
      ),

      // ==================== Warehouses ====================
      GoRoute(
        path: AppConstants.routeWarehouses,
        name: 'warehouses',
        builder: (context, state) => const WarehousesListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'warehouses-add',
            builder: (context, state) => const WarehouseFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'warehouses-edit',
            builder: (context, state) => WarehouseFormScreen(
              warehouseId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id/count',
            name: 'warehouses-count',
            builder: (context, state) => StockCountScreen(
              warehouseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: ':id/movements/add',
            name: 'warehouses-movements-add',
            builder: (context, state) => StockMovementFormScreen(
              warehouseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: ':id/movements',
            name: 'warehouses-movements',
            builder: (context, state) => StockMovementsScreen(
              warehouseId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'warehouses-details',
            builder: (context, state) => WarehouseDetailsScreen(
              warehouseId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Stock (all) ====================
      GoRoute(
        path: AppConstants.routeStock,
        name: 'stock',
        builder: (context, state) => const StockMovementsScreen(),
      ),

      // ==================== Customers ====================
      GoRoute(
        path: AppConstants.routeCustomers,
        name: 'customers',
        builder: (context, state) => const CustomersListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'customers-add',
            builder: (context, state) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'customers-edit',
            builder: (context, state) => CustomerFormScreen(
              customerId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'customers-details',
            builder: (context, state) => CustomerDetailsScreen(
              customerId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Suppliers ====================
      GoRoute(
        path: AppConstants.routeSuppliers,
        name: 'suppliers',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'الموردين',
          icon: Icons.local_shipping,
        ),
      ),

      // ==================== Invoices ====================
      GoRoute(
        path: AppConstants.routeAddInvoice,
        name: 'invoices-add',
        builder: (context, state) => const InvoiceFormScreen(),
      ),
      GoRoute(
        path: AppConstants.routeEditInvoice,
        name: 'invoices-edit',
        builder: (context, state) => InvoiceFormScreen(
          invoiceId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppConstants.routeInvoices,
        name: 'invoices',
        builder: (context, state) => const InvoicesListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'invoices-details',
            builder: (context, state) => InvoiceDetailsScreen(
              invoiceId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Reports ====================
      GoRoute(
        path: AppConstants.routeReports,
        name: 'reports',
        builder: (context, state) => const ReportsHomeScreen(),
        routes: [
          GoRoute(
            path: 'sales',
            name: 'reports-sales',
            builder: (context, state) => const SalesReportScreen(),
          ),
          GoRoute(
            path: 'top-products',
            name: 'reports-top-products',
            builder: (context, state) => const TopProductsScreen(),
          ),
          GoRoute(
            path: 'profit',
            name: 'reports-profit',
            builder: (context, state) => const ProfitReportScreen(),
          ),
        ],
      ),

      // ==================== Maintenance ====================
      // ⚠️ الترتيب مهم: add و edit قبل :id
      GoRoute(
        path: AppConstants.routeAddMaintenance,
        name: 'maintenance-add',
        builder: (context, state) => const MaintenanceFormScreen(),
      ),
      GoRoute(
        path: '/maintenance/edit/:id',
        name: 'maintenance-edit',
        builder: (context, state) => MaintenanceFormScreen(
          ticketId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppConstants.routeMaintenance,
        name: 'maintenance',
        builder: (context, state) => const MaintenanceListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'maintenance-details',
            builder: (context, state) => MaintenanceDetailsScreen(
              ticketId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ==================== Settings ====================
      GoRoute(
        path: AppConstants.routeSettings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'company',
            name: 'settings-company',
            builder: (context, state) => const CompanyInfoScreen(),
          ),
          GoRoute(
            path: 'attendance',
            name: 'settings-attendance',
            builder: (context, state) => const AttendanceSettingsScreen(),
          ),
          GoRoute(
            path: 'location',
            name: 'settings-location',
            builder: (context, state) => const LocationScreen(),
          ),
          GoRoute(
            path: 'currency',
            name: 'settings-currency',
            builder: (context, state) => const CurrencyScreen(),
          ),
          GoRoute(
            path: 'payroll',
            name: 'settings-payroll',
            builder: (context, state) => const PayrollSettingsScreen(),
          ),
          GoRoute(
            path: 'inventory',
            name: 'settings-inventory',
            builder: (context, state) => const InventorySettingsScreen(),
          ),
          GoRoute(
            path: 'job-titles',
            name: 'settings-job-titles',
            builder: (context, state) => const JobTitlesScreen(),
          ),
          GoRoute(
            path: 'departments',
            name: 'settings-departments',
            builder: (context, state) => const DepartmentsScreen(),
          ),
          GoRoute(
            path: 'appearance',
            name: 'settings-appearance',
            builder: (context, state) => const AppearanceScreen(),
          ),
          GoRoute(
            path: 'system-info',
            name: 'settings-system-info',
            builder: (context, state) => const SystemInfoScreen(),
          ),
        ],
      ),
    ],

    // ==================== Error Page ====================
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text('الصفحة غير موجودة', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.routeLanding),
              child: const Text('الرجوع للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}

// =====================================================
// Placeholder Screen
// =====================================================
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'قيد الإنشاء',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

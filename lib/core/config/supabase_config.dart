// lib/core/config/supabase_config.dart

class SupabaseConfig {
  // ⚠️ استبدل القيم دي بمفاتيحك من Supabase
  static const String supabaseUrl = 'https://pvjhvuqlyfuzrcdphsce.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2amh2dXFseWZ1enJjZHBoc2NlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA4NTU1OTEsImV4cCI6MjEwNjQzMTU5MX0.g1dyk-S0BhJKnziqC0xKjTPS61VxoCRtalJYz0fBDgU';

  // جدول أسماء — عشان نستخدمهم في الكود بدل ما نكتبهم يدوي
  static const String tableProfiles = 'profiles';
  static const String tableRoles = 'roles';
  static const String tableSettings = 'settings';
  static const String tableEmployees = 'employees';
  static const String tableAttendance = 'attendance';
  static const String tableLeaveRequests = 'leave_requests';
  static const String tableHolidays = 'holidays';
  static const String tableAdvances = 'advances';
  static const String tablePayrolls = 'payrolls';
  static const String tableCategories = 'categories';
  static const String tableBrands = 'brands';
  static const String tableProducts = 'products';
  static const String tableWarehouses = 'warehouses';
  static const String tableStock = 'stock';
  static const String tableStockMovements = 'stock_movements';
  static const String tableCustomers = 'customers';
  static const String tableSuppliers = 'suppliers';
  static const String tableInvoices = 'invoices';
  static const String tableInvoiceItems = 'invoice_items';
  static const String tablePayments = 'payments';
  static const String tableMaintenanceTickets = 'maintenance_tickets';
  static const String tableMaintenanceParts = 'maintenance_parts';
}

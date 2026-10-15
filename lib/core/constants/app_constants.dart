// lib/core/constants/app_constants.dart

class AppConstants {
  // =====================================================
  // معلومات الشركة
  // =====================================================
  static const String appName = 'Moonstar ERP';
  static const String companyName = 'Moonstar';
  static const String appVersion = '1.0.0';

  // =====================================================
  // أسماء الجداول في Supabase
  // =====================================================
  static const String profileTable = 'profiles';
  static const String rolesTable = 'roles';
  static const String settingsTable = 'settings';
  static const String auditLogTable = 'audit_log';

  // HR
  static const String employeesTable = 'employees';
  static const String attendanceTable = 'attendance';
  static const String holidaysTable = 'holidays';
  static const String advancesTable = 'advances';
  static const String payrollsTable = 'payrolls';
  static const String jobTitlesTable = 'job_titles';
  static const String departmentsTable = 'departments';
  static const String leaveRequestsTable = 'leave_requests';

  // Products / Inventory
  static const String categoriesTable = 'categories';
  static const String brandsTable = 'brands';
  static const String productsTable = 'products';
  static const String warehousesTable = 'warehouses';
  static const String stockTable = 'stock';
  static const String stockMovementsTable = 'stock_movements';

  // Partners
  static const String customersTable = 'customers';
  static const String suppliersTable = 'suppliers';

  // Sales
  static const String invoicesTable = 'invoices';
  static const String invoiceItemsTable = 'invoice_items';
  static const String paymentsTable = 'payments';

  // Maintenance
  static const String maintenanceTicketsTable = 'maintenance_tickets';
  static const String maintenancePartsTable = 'maintenance_parts';

  // Views
  static const String vLowStock = 'v_low_stock';

  // =====================================================
  // الأدوار (Roles)
  // =====================================================
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleAccountant = 'accountant';
  static const String roleStorekeeper = 'storekeeper';
  static const String roleCashier = 'cashier';
  static const String roleTechnician = 'technician';

  static const List<String> allRoles = [
    roleAdmin,
    roleManager,
    roleAccountant,
    roleStorekeeper,
    roleCashier,
    roleTechnician,
  ];

  static const Map<String, String> roleNamesAr = {
    roleAdmin: 'أدمن',
    roleManager: 'مدير',
    roleAccountant: 'محاسب',
    roleStorekeeper: 'أمين مخزن',
    roleCashier: 'كاشير',
    roleTechnician: 'فني صيانة',
  };

  static const List<String> rolesWithoutAttendance = [
    roleAdmin,
    roleManager,
  ];

  static bool hasAttendance(String? roleCode) {
    if (roleCode == null) return false;
    return !rolesWithoutAttendance.contains(roleCode);
  }

  // =====================================================
  // حالات الحضور
  // =====================================================
  static const String attendancePresent = 'present';
  static const String attendanceLate = 'late';
  static const String attendanceVeryLate = 'very_late';
  static const String attendanceAbsent = 'absent';
  static const String attendanceWeekend = 'weekend';

  static const Map<String, String> attendanceStatusAr = {
    attendancePresent: 'حاضر',
    attendanceLate: 'متأخر',
    attendanceVeryLate: 'حضر متأخراً جداً',
    attendanceAbsent: 'غايب',
    attendanceWeekend: 'إجازة أسبوعية',
  };

  static const Map<String, int> attendanceStatusColors = {
    attendancePresent: 0xFF43A047,
    attendanceLate: 0xFFFB8C00,
    attendanceVeryLate: 0xFFE53935,
    attendanceAbsent: 0xFFE53935,
    attendanceWeekend: 0xFF1E88E5,
  };

  // =====================================================
  // أنواع الإجازات
  // =====================================================
  static const String leaveTypeAnnual = 'annual';
  static const String leaveTypeSick = 'sick';
  static const String leaveTypeUnpaid = 'unpaid';
  static const String leaveTypeEmergency = 'emergency';
  static const String leaveTypeOther = 'other';

  static const Map<String, String> leaveTypeAr = {
    leaveTypeAnnual: 'سنوية',
    leaveTypeSick: 'مرضية',
    leaveTypeUnpaid: 'بدون راتب',
    leaveTypeEmergency: 'طارئة',
    leaveTypeOther: 'أخرى',
  };

  // =====================================================
  // الفواتير (البيانات)
  // =====================================================
  static const String invoiceTypeSale = 'sale';
  static const String invoiceTypeSaleReturn = 'sale_return';
  static const String invoiceTypeQuote = 'quote';

  static const Map<String, String> invoiceTypeAr = {
    invoiceTypeSale: 'بيع',
    invoiceTypeSaleReturn: 'مرتجع بيع',
    invoiceTypeQuote: 'عرض سعر',
  };

  static const String invoiceDraft = 'draft';
  static const String invoiceQuote = 'quote';
  static const String invoiceConfirmed = 'confirmed';
  static const String invoicePaid = 'paid';
  static const String invoicePartial = 'partial';
  static const String invoiceCancelled = 'cancelled';

  static const Map<String, String> invoiceStatusAr = {
    invoiceDraft: 'مسودة',
    invoiceQuote: 'عرض سعر',
    invoiceConfirmed: 'مؤكدة',
    invoicePaid: 'مدفوعة',
    invoicePartial: 'مدفوعة جزئياً',
    invoiceCancelled: 'ملغية',
  };

  static const String paymentCash = 'cash';
  static const String paymentVodafoneCash = 'vodafone_cash';
  static const String paymentInstapay = 'instapay';

  static const Map<String, String> paymentMethodAr = {
    paymentCash: 'كاش',
    paymentVodafoneCash: 'فودافون كاش',
    paymentInstapay: 'إنستاباي',
  };

  static const String valueTypeFixed = 'fixed';
  static const String valueTypePercentage = 'percentage';

  static const String defaultInvoiceTitle = 'بيان';

  // =====================================================
  // حركات المخزون
  // =====================================================
  static const String movementPurchaseIn = 'purchase_in';
  static const String movementSaleOut = 'sale_out';
  static const String movementTransferIn = 'transfer_in';
  static const String movementTransferOut = 'transfer_out';
  static const String movementAdjustment = 'adjustment';
  static const String movementMaintenanceOut = 'maintenance_out';
  static const String movementReturnIn = 'return_in';
  static const String movementReturnOut = 'return_out';

  static const Map<String, String> movementTypeAr = {
    movementPurchaseIn: 'إدخال شراء',
    movementSaleOut: 'إخراج بيع',
    movementTransferIn: 'تحويل داخل',
    movementTransferOut: 'تحويل خارج',
    movementAdjustment: 'تسوية',
    movementMaintenanceOut: 'قطع صيانة',
    movementReturnIn: 'مرتجع داخل',
    movementReturnOut: 'مرتجع خارج',
  };

  // =====================================================
  // حالات الصيانة
  // =====================================================
  static const String maintNew = 'new';
  static const String maintDiagnosing = 'diagnosing';
  static const String maintRepairing = 'repairing';
  static const String maintWaitingParts = 'waiting_parts';
  static const String maintReady = 'ready';
  static const String maintDelivered = 'delivered';
  static const String maintCancelled = 'cancelled';

  static const Map<String, String> maintStatusAr = {
    maintNew: 'جديدة',
    maintDiagnosing: 'قيد الفحص',
    maintRepairing: 'قيد الإصلاح',
    maintWaitingParts: 'في انتظار قطع',
    maintReady: 'جاهزة',
    maintDelivered: 'تم التسليم',
    maintCancelled: 'ملغية',
  };

  static const String priorityLow = 'low';
  static const String priorityNormal = 'normal';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  static const Map<String, String> priorityAr = {
    priorityLow: 'منخفضة',
    priorityNormal: 'عادية',
    priorityHigh: 'عالية',
    priorityUrgent: 'عاجلة',
  };

  // =====================================================
  // وحدات القياس
  // =====================================================
  static const List<String> units = [
    'قطعة',
    'كرتونة',
    'كيلو',
    'متر',
    'لتر',
    'علبة',
  ];

  // =====================================================
  // إعدادات عامة
  // =====================================================
  static const String currency = 'ج.م';
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy - HH:mm';

  // =====================================================
  // إعدادات الشيفت
  // =====================================================
  static const String shiftStartTime = '13:30';
  static const String shiftEndTime = '22:30';
  static const String absenceMarkTime = '14:30';
  static const int graceMinutes = 15;
  static const int weekendDay = 0;
  static const int attendanceRadiusMeters = 50;

  // =====================================================
  // Payroll
  // =====================================================
  static const int payrollCycleStartDay = 5;

  // =====================================================
  // Pagination
  // =====================================================
  static const int defaultPageSize = 20;
  static const int shopPageSize = 20;

  // =====================================================
  // Storage Keys
  // =====================================================
  static const String keyUserSession = 'user_session';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyDeviceId = 'device_id';

  // =====================================================
  // Routes (أسماء الشاشات)
  // =====================================================

  // 🏠 Landing (الصفحة الرئيسية)
  static const String routeLanding = '/';

  // ℹ️ About Page
  static const String routeAbout = '/about';

  // 📞 Contact Page
  static const String routeContact = '/contact';

  // 🛒 Shop (كل المنتجات)
  static const String routeShop = '/shop';
  static const String routeShopProduct = '/shop/product/:id';
  static const String routeShopCategory = '/shop/category/:id';

  // Root
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeHome = '/home';

  // Admin
  static const String routeDevicesManagement = '/admin/devices';

  // Employees
  static const String routeEmployees = '/employees';
  static const String routeEmployeeDetails = '/employees/:id';
  static const String routeAddEmployee = '/employees/add';
  static const String routeEditEmployee = '/employees/edit/:id';

  // Attendance
  static const String routeAttendance = '/attendance';
  static const String routeMyAttendance = '/attendance/me';
  static const String routeAttendanceHistory = '/attendance/history';
  static const String routeAttendanceCheckIn = '/attendance/checkin';
  static const String routeAttendanceDetails = '/attendance/:id';

  // Advances
  static const String routeAdvances = '/advances';
  static const String routeMyAdvances = '/advances/me';
  static const String routeAddAdvance = '/advances/add';
  static const String routeEditAdvance = '/advances/edit/:id';

  // Payrolls
  static const String routePayrolls = '/payrolls';
  static const String routeMyPayrolls = '/payrolls/me';
  static const String routePayrollDetails = '/payrolls/:id';

  // Products
  static const String routeProducts = '/products';
  static const String routeAddProduct = '/products/add';
  static const String routeEditProduct = '/products/edit/:id';
  static const String routeProductDetails = '/products/:id';
  static const String routeCategories = '/categories';
  static const String routeBrands = '/brands';

  // Inventory
  static const String routeWarehouses = '/warehouses';
  static const String routeAddWarehouse = '/warehouses/add';
  static const String routeEditWarehouse = '/warehouses/edit/:id';
  static const String routeWarehouseDetails = '/warehouses/:id';
  static const String routeStockCount = '/warehouses/:id/count';
  static const String routeStockMovements = '/warehouses/:id/movements';
  static const String routeAddStockMovement = '/warehouses/:id/movements/add';
  static const String routeStock = '/stock';

  // Partners
  static const String routeCustomers = '/customers';
  static const String routeAddCustomer = '/customers/add';
  static const String routeEditCustomer = '/customers/edit/:id';
  static const String routeCustomerDetails = '/customers/:id';
  static const String routeSuppliers = '/suppliers';

  // Invoices
  static const String routeInvoices = '/invoices';
  static const String routeAddInvoice = '/invoices/add';
  static const String routeEditInvoice = '/invoices/edit/:id';
  static const String routeInvoiceDetails = '/invoices/:id';

  // Reports
  static const String routeReports = '/reports';
  static const String routeSalesReport = '/reports/sales';
  static const String routeTopProducts = '/reports/top-products';
  static const String routeProfitReport = '/reports/profit';

  // Maintenance
  static const String routeMaintenance = '/maintenance';
  static const String routeAddMaintenance = '/maintenance/add';
  static const String routeEditMaintenance = '/maintenance/edit/:id';
  static const String routeMaintenanceDetails = '/maintenance/:id';

  // Settings
  static const String routeSettings = '/settings';

  // =====================================================
  // Helpers
  // =====================================================
  static String attendanceStatusLabel(String? status) {
    if (status == null) return '-';
    return attendanceStatusAr[status] ?? status;
  }

  static String roleName(String? code) {
    if (code == null) return '-';
    return roleNamesAr[code] ?? code;
  }

  static String invoiceStatusLabel(String? status) {
    if (status == null) return '-';
    return invoiceStatusAr[status] ?? status;
  }

  static String invoiceTypeLabel(String? type) {
    if (type == null) return '-';
    return invoiceTypeAr[type] ?? type;
  }

  static String paymentMethodLabel(String? method) {
    if (method == null) return '-';
    return paymentMethodAr[method] ?? method;
  }

  static String movementTypeLabel(String? type) {
    if (type == null) return '-';
    return movementTypeAr[type] ?? type;
  }

  static String maintStatusLabel(String? status) {
    if (status == null) return '-';
    return maintStatusAr[status] ?? status;
  }

  static String priorityLabel(String? priority) {
    if (priority == null) return '-';
    return priorityAr[priority] ?? priority;
  }
}

// =====================================================
// 🏢 Company Info (Landing Page)
// =====================================================
class CompanyInfo {
  // Hero
  static const String heroTitle = '16 عام من النجاح ولسه زى ما احنا';
  static const String heroSubtitle =
      'الوكيل الوحيد لشركة Moonstar فى مصر والشرق الأوسط';
  static const String heroCtaShop = 'تسوق الآن';
  static const String heroCtaAbout = 'تعرف علينا';

  // Contact
  static const String phone = '01026265026';
  static const String whatsapp = '01026265026';
  static const String address = '7 ش جمال عبدالناصر - أرض الشركة / الشرابية';
  static const String socialHandle = 'moonstar';
  static const String email = 'info@moonstar.com';
  static const String googleMapsUrl =
      'https://maps.app.goo.gl/NHY2dPmPh4Pkp4hi9';

  // About
  static const String aboutTitle = 'من نحن';
  static const String aboutDescription =
      'منذ أكثر من 16 عاماً، تعمل شركة Moonstar على تقديم أفضل حلول '
      'الإضاءة والصوتيات والشاشات في مصر والشرق الأوسط. نقدم خدماتنا '
      'للمسارح والفعاليات والقاعات والمولات بأحدث التقنيات وأعلى معايير '
      'الجودة العالمية.';

  static const String aboutMission =
      'رسالتنا: تقديم منتجات وخدمات بجودة عالمية بأسعار تنافسية، '
      'مع الحفاظ على أعلى معايير خدمة العملاء.';

  // Stats
  static const int statsProducts = 500;
  static const int statsClients = 1000;
  static const int statsYears = 15;

  // Hero Slideshow Images
  static const List<String> heroImages = [
    'assets/images/bg_1.jpg',
    'assets/images/bg_2.jpg',
    'assets/images/bg_3.jpg',
    'assets/images/bg_4.jpg',
  ];

  // Features
  static const List<Map<String, String>> features = [
    {
      'title': 'سرعة التنفيذ',
      'description': 'توصيل وتركيب سريع في جميع المحافظات',
      'icon': 'speed',
    },
    {
      'title': 'جودة عالمية',
      'description': 'منتجات أصلية بأعلى معايير الجودة',
      'icon': 'quality',
    },
    {
      'title': 'خبرة 15+ سنة',
      'description': 'خبرة طويلة في السوق المصري والعربي',
      'icon': 'experience',
    },
    {
      'title': 'دعم فني',
      'description': 'فريق دعم متخصص على مدار الساعة',
      'icon': 'support',
    },
  ];
}

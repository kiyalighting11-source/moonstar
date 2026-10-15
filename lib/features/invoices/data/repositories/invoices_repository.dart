// lib/features/invoices/data/repositories/invoices_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';

class InvoicesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // Select queries (مع العلاقات)
  // =====================================================
  static const String _selectWithRelations = '''
    *,
    customers!customer_id (name, phone),
    suppliers!supplier_id (name),
    warehouses!warehouse_id (name),
    creator:profiles!created_by (full_name)
  ''';

  static const String _selectFull = '''
    *,
    customers!customer_id (name, phone),
    suppliers!supplier_id (name),
    warehouses!warehouse_id (name),
    creator:profiles!created_by (full_name),
    invoice_items (
      *,
      products!product_id (name, sku, main_image_url)
    ),
    payments (
      *,
      creator:profiles!created_by (full_name)
    )
  ''';

  // =====================================================
  // QUERIES
  // =====================================================

  /// كل الفواتير (مع فلترة اختيارية)
  Future<List<InvoiceModel>> getAllInvoices({
    String? type,
    String? status,
    String? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    int limit = 200,
  }) async {
    var query =
        _supabase.from(AppConstants.invoicesTable).select(_selectWithRelations);

    if (type != null) query = query.eq('type', type);
    if (status != null) query = query.eq('status', status);
    if (customerId != null) query = query.eq('customer_id', customerId);
    if (fromDate != null) {
      query = query.gte('invoice_date', _fmt(fromDate));
    }
    if (toDate != null) {
      query = query.lte('invoice_date', _fmt(toDate));
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.or('invoice_number.ilike.%$q%,notes.ilike.%$q%');
    }

    final data = await query
        .order('invoice_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => InvoiceModel.fromJson(e)).toList();
  }

  /// فاتورة واحدة بالتفاصيل الكاملة
  Future<InvoiceModel?> getInvoiceById(String id) async {
    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .select(_selectFull)
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return InvoiceModel.fromJson(data);
  }

  /// فواتير عميل معين
  Future<List<InvoiceModel>> getCustomerInvoices(String customerId) async {
    return getAllInvoices(customerId: customerId);
  }

  /// الفواتير المستحقة (partial + confirmed)
  Future<List<InvoiceModel>> getUnpaidInvoices() async {
    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .select(_selectWithRelations)
        .inFilter('status', ['confirmed', 'partial'])
        .gt('due_amount', 0)
        .order('due_date', ascending: true, nullsFirst: false);

    return (data as List).map((e) => InvoiceModel.fromJson(e)).toList();
  }

  // =====================================================
  // CREATE / UPDATE
  // =====================================================

  /// إنشاء فاتورة جديدة (بدون بنود)
  /// ⭐ بنشيل الحقول اللي الـ triggers بتحسبها
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    final userId = _supabase.auth.currentUser?.id;

    final json = invoice.toJson();

    // ⭐ نضمن إن invoice_number فاضي عشان الـ trigger يولّد واحد جديد
    json['invoice_number'] = '';
    json['created_by'] = userId;

    // ⭐ نشيل الحقول اللي الـ triggers بتحدّثها
    // (عشان ما تتعارضش مع الحسابات التلقائية)
    json.remove('paid_amount');
    json.remove('due_amount');
    json.remove('subtotal');
    json.remove('total_extra');
    json.remove('discount');
    json.remove('tax');
    json.remove('total');
    // ⚠️ نسيب status لأنه محدد من الفورم (draft أو confirmed)

    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .insert(json)
        .select(_selectWithRelations)
        .single();

    return InvoiceModel.fromJson(data);
  }

  /// تحديث فاتورة
  /// ⭐ ملاحظة مهمة: بنشيل الحقول المحسوبة عشان ما تتصفّرش
  ///    (خصوصاً paid_amount و due_amount)
  Future<InvoiceModel> updateInvoice(InvoiceModel invoice) async {
    final json = invoice.toJson();

    // ⭐ نشيل الحقول اللي مش المفروض تتغير من Flutter
    json.remove('invoice_number'); // الرقم بيتولّد مرة واحدة بس
    json.remove('paid_amount'); // بيتحسب من جدول payments
    json.remove('due_amount'); // الـ trigger بيحسبه
    json.remove('subtotal'); // الـ trigger بيحسبه
    json.remove('total_extra'); // الـ trigger بيحسبه
    json.remove('discount'); // الـ trigger بيحسبه
    json.remove('tax'); // الـ trigger بيحسبه
    json.remove('total'); // الـ trigger بيحسبه
    json.remove('status'); // الـ triggers بتحدّثه
    json.remove('created_by');
    json.remove('created_at');

    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .update(json)
        .eq('id', invoice.id)
        .select(_selectWithRelations)
        .single();

    return InvoiceModel.fromJson(data);
  }

  /// حذف فاتورة (مع بنودها ودفعاتها)
  Future<void> deleteInvoice(String id) async {
    await _supabase.from(AppConstants.invoicesTable).delete().eq('id', id);
  }

  // =====================================================
  // ITEMS
  // =====================================================

  /// إضافة بنود للفاتورة
  Future<List<InvoiceItemModel>> addItems({
    required String invoiceId,
    required List<InvoiceItemModel> items,
  }) async {
    if (items.isEmpty) return [];

    final payload = items
        .map((item) => {
              ...item.toJson(),
              'invoice_id': invoiceId,
            })
        .toList();

    final data = await _supabase
        .from(AppConstants.invoiceItemsTable)
        .insert(payload)
        .select('*, products!product_id (name, sku, main_image_url)');

    return (data as List).map((e) => InvoiceItemModel.fromJson(e)).toList();
  }

  /// حذف كل بنود الفاتورة
  Future<void> clearItems(String invoiceId) async {
    await _supabase
        .from(AppConstants.invoiceItemsTable)
        .delete()
        .eq('invoice_id', invoiceId);
  }

  /// تعديل بند
  Future<InvoiceItemModel> updateItem(InvoiceItemModel item) async {
    final data = await _supabase
        .from(AppConstants.invoiceItemsTable)
        .update(item.toJson())
        .eq('id', item.id)
        .select('*, products!product_id (name, sku, main_image_url)')
        .single();

    return InvoiceItemModel.fromJson(data);
  }

  /// حذف بند
  Future<void> deleteItem(String itemId) async {
    await _supabase
        .from(AppConstants.invoiceItemsTable)
        .delete()
        .eq('id', itemId);
  }

  // =====================================================
  // STATUS TRANSITIONS
  // =====================================================

  /// تأكيد الفاتورة (بيشغّل stock movement تلقائياً من الـ trigger)
  Future<InvoiceModel> confirmInvoice(String id) async {
    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .update({'status': 'confirmed'})
        .eq('id', id)
        .select(_selectWithRelations)
        .single();

    return InvoiceModel.fromJson(data);
  }

  /// إلغاء الفاتورة
  Future<InvoiceModel> cancelInvoice(String id) async {
    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .update({'status': 'cancelled'})
        .eq('id', id)
        .select(_selectWithRelations)
        .single();

    return InvoiceModel.fromJson(data);
  }

  /// إرجاع الفاتورة لمسودة (لو كانت مؤكدة ومفيش دفعات)
  Future<InvoiceModel> revertToDraft(String id) async {
    final data = await _supabase
        .from(AppConstants.invoicesTable)
        .update({'status': 'draft'})
        .eq('id', id)
        .select(_selectWithRelations)
        .single();

    return InvoiceModel.fromJson(data);
  }

  // =====================================================
  // PAYMENTS
  // =====================================================

  /// إضافة دفعة
  /// ⭐ الـ trigger `trg_payments_update_invoice` بيحدّث
  ///    paid_amount و due_amount أوتوماتيك
  Future<PaymentModel> addPayment({
    required String invoiceId,
    required double amount,
    required String method,
    DateTime? paymentDate,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final data = await _supabase
        .from(AppConstants.paymentsTable)
        .insert({
          'invoice_id': invoiceId,
          'amount': amount,
          'method': method,
          'payment_date': _fmt(paymentDate ?? DateTime.now()),
          'notes': notes,
          'created_by': userId,
        })
        .select('*, creator:profiles!created_by (full_name)')
        .single();

    return PaymentModel.fromJson(data);
  }

  /// دفعات فاتورة
  Future<List<PaymentModel>> getInvoicePayments(String invoiceId) async {
    final data = await _supabase
        .from(AppConstants.paymentsTable)
        .select('*, creator:profiles!created_by (full_name)')
        .eq('invoice_id', invoiceId)
        .order('payment_date', ascending: false);

    return (data as List).map((e) => PaymentModel.fromJson(e)).toList();
  }

  /// حذف دفعة
  Future<void> deletePayment(String paymentId) async {
    await _supabase
        .from(AppConstants.paymentsTable)
        .delete()
        .eq('id', paymentId);
  }

  // =====================================================
  // STATS
  // =====================================================

  /// إحصائيات سريعة
  Future<Map<String, dynamic>> getStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // عدد الفواتير الكلي
    final allCount =
        await _supabase.from(AppConstants.invoicesTable).select('id').count();

    // فواتير الشهر
    final monthCount = await _supabase
        .from(AppConstants.invoicesTable)
        .select('id')
        .gte('invoice_date', _fmt(monthStart))
        .count();

    // المستحقات (partial + confirmed)
    final unpaidData = await _supabase
        .from(AppConstants.invoicesTable)
        .select('due_amount')
        .inFilter('status', ['confirmed', 'partial']);

    double totalDue = 0;
    for (final row in (unpaidData as List)) {
      totalDue += (row['due_amount'] as num?)?.toDouble() ?? 0;
    }

    // مبيعات الشهر
    final salesData = await _supabase
        .from(AppConstants.invoicesTable)
        .select('total')
        .eq('type', 'sale')
        .inFilter('status', ['confirmed', 'paid', 'partial']).gte(
            'invoice_date', _fmt(monthStart));

    double monthSales = 0;
    for (final row in (salesData as List)) {
      monthSales += (row['total'] as num?)?.toDouble() ?? 0;
    }

    return {
      'all_count': allCount.count,
      'month_count': monthCount.count,
      'total_due': totalDue,
      'month_sales': monthSales,
    };
  }

  // =====================================================
  // HELPERS
  // =====================================================

  /// تنسيق التاريخ لـ yyyy-MM-dd
  static String _fmt(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

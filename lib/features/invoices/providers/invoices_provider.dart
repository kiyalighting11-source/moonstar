// lib/features/invoices/providers/invoices_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/invoice_item_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/payment_model.dart';
import '../data/repositories/invoices_repository.dart';

// =====================================================
// Repository
// =====================================================
final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository();
});

// =====================================================
// Filter State
// =====================================================
class InvoicesFilter {
  final String? type; // sale / sale_return / quote
  final String?
      status; // draft / quote / confirmed / paid / partial / cancelled
  final String? customerId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? search;

  const InvoicesFilter({
    this.type,
    this.status,
    this.customerId,
    this.fromDate,
    this.toDate,
    this.search,
  });

  InvoicesFilter copyWith({
    String? type,
    String? status,
    String? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    bool clearType = false,
    bool clearStatus = false,
    bool clearCustomer = false,
    bool clearDates = false,
    bool clearSearch = false,
  }) {
    return InvoicesFilter(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

final invoicesFilterProvider = StateProvider<InvoicesFilter>((ref) {
  return const InvoicesFilter();
});

// =====================================================
// قائمة الفواتير
// =====================================================
final invoicesListProvider =
    FutureProvider.autoDispose<List<InvoiceModel>>((ref) async {
  final repo = ref.watch(invoicesRepositoryProvider);
  return await repo.getAllInvoices();
});

// =====================================================
// الفواتير المفلترة
// =====================================================
final filteredInvoicesProvider =
    FutureProvider.autoDispose<List<InvoiceModel>>((ref) async {
  final repo = ref.watch(invoicesRepositoryProvider);
  final filter = ref.watch(invoicesFilterProvider);

  return await repo.getAllInvoices(
    type: filter.type,
    status: filter.status,
    customerId: filter.customerId,
    fromDate: filter.fromDate,
    toDate: filter.toDate,
    search: filter.search,
  );
});

// =====================================================
// فواتير عميل معين
// =====================================================
final customerInvoicesProvider = FutureProvider.autoDispose
    .family<List<InvoiceModel>, String>((ref, customerId) async {
  final repo = ref.watch(invoicesRepositoryProvider);
  return await repo.getCustomerInvoices(customerId);
});

// =====================================================
// الفواتير المستحقة
// =====================================================
final unpaidInvoicesProvider =
    FutureProvider.autoDispose<List<InvoiceModel>>((ref) async {
  final repo = ref.watch(invoicesRepositoryProvider);
  return await repo.getUnpaidInvoices();
});

// =====================================================
// فاتورة واحدة
// =====================================================
final invoiceByIdProvider =
    FutureProvider.autoDispose.family<InvoiceModel?, String>((ref, id) async {
  // ⭐ حماية: لو الـ id مش UUID، ارجع null فوراً
  if (!_isValidUuid(id)) return null;

  final repo = ref.watch(invoicesRepositoryProvider);
  return await repo.getInvoiceById(id);
});

// =====================================================
// دفعات فاتورة
// =====================================================
final invoicePaymentsProvider = FutureProvider.autoDispose
    .family<List<PaymentModel>, String>((ref, invoiceId) async {
  final repo = ref.watch(invoicesRepositoryProvider);
  return await repo.getInvoicePayments(invoiceId);
});

// =====================================================
// إحصائيات
// =====================================================
final invoicesStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(invoicesRepositoryProvider);
  return await repo.getStats();
});

// =====================================================
// Controller
// =====================================================
class InvoicesController extends StateNotifier<AsyncValue<void>> {
  InvoicesController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final InvoicesRepository _repo;
  final Ref _ref;

  // =====================================================
  // CREATE / UPDATE / DELETE
  // =====================================================

  /// إنشاء فاتورة + إضافة البنود
  Future<InvoiceModel?> createInvoice({
    required InvoiceModel invoice,
    required List<InvoiceItemModel> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1) إنشاء الفاتورة
      final created = await _repo.createInvoice(invoice);

      // 2) إضافة البنود
      if (items.isNotEmpty) {
        await _repo.addItems(
          invoiceId: created.id,
          items: items,
        );
      }

      state = const AsyncValue.data(null);
      _refreshAll();
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// تعديل فاتورة (بدون تعديل البنود)
  Future<bool> updateInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateInvoice(invoice);
      state = const AsyncValue.data(null);
      _refreshAll(id: invoice.id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// تعديل فاتورة + استبدال البنود
  Future<bool> updateInvoiceWithItems({
    required InvoiceModel invoice,
    required List<InvoiceItemModel> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1) تعديل الفاتورة
      await _repo.updateInvoice(invoice);

      // 2) مسح البنود القديمة
      await _repo.clearItems(invoice.id);

      // 3) إضافة البنود الجديدة
      if (items.isNotEmpty) {
        await _repo.addItems(
          invoiceId: invoice.id,
          items: items,
        );
      }

      state = const AsyncValue.data(null);
      _refreshAll(id: invoice.id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// حذف فاتورة
  Future<bool> deleteInvoice(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteInvoice(id);
      state = const AsyncValue.data(null);
      _refreshAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // =====================================================
  // STATUS
  // =====================================================

  /// تأكيد الفاتورة (بيشغّل stock movement)
  Future<InvoiceModel?> confirmInvoice(String id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.confirmInvoice(id);
      state = const AsyncValue.data(null);
      _refreshAll(id: id);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// إلغاء الفاتورة
  Future<InvoiceModel?> cancelInvoice(String id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.cancelInvoice(id);
      state = const AsyncValue.data(null);
      _refreshAll(id: id);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// إرجاع لمسودة
  Future<InvoiceModel?> revertToDraft(String id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.revertToDraft(id);
      state = const AsyncValue.data(null);
      _refreshAll(id: id);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  // =====================================================
  // PAYMENTS
  // =====================================================

  /// إضافة دفعة
  Future<PaymentModel?> addPayment({
    required String invoiceId,
    required double amount,
    required String method,
    DateTime? paymentDate,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.addPayment(
        invoiceId: invoiceId,
        amount: amount,
        method: method,
        paymentDate: paymentDate,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      _refreshAll(id: invoiceId);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// حذف دفعة
  Future<bool> deletePayment(String paymentId, String invoiceId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deletePayment(paymentId);
      state = const AsyncValue.data(null);
      _refreshAll(id: invoiceId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // =====================================================
  // REFRESH
  // =====================================================

  void _refreshAll({String? id}) {
    _ref.invalidate(invoicesListProvider);
    _ref.invalidate(filteredInvoicesProvider);
    _ref.invalidate(unpaidInvoicesProvider);
    _ref.invalidate(invoicesStatsProvider);

    if (id != null) {
      _ref.invalidate(invoiceByIdProvider(id));
      _ref.invalidate(invoicePaymentsProvider(id));
    }
  }
}

final invoicesControllerProvider =
    StateNotifierProvider<InvoicesController, AsyncValue<void>>((ref) {
  return InvoicesController(ref.read(invoicesRepositoryProvider), ref);
});

// =====================================================
// UUID validation
// =====================================================
final RegExp _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool _isValidUuid(String s) => _uuidRegex.hasMatch(s);

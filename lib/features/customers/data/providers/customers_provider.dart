// lib/features/customers/data/providers/customers_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_model.dart';
import '../repository/customers_repository.dart';

// =====================================================
// Repository
// =====================================================
final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository();
});

// =====================================================
// قائمة العملاء
// =====================================================
final customersListProvider =
    FutureProvider.autoDispose<List<CustomerModel>>((ref) async {
  final repo = ref.watch(customersRepositoryProvider);
  return await repo.getAllCustomers();
});

// =====================================================
// فلتر العملاء
// =====================================================
class CustomersFilter {
  final String? search;
  final String? type;
  final bool onlyActive;

  const CustomersFilter({
    this.search,
    this.type,
    this.onlyActive = false,
  });

  CustomersFilter copyWith({
    String? search,
    String? type,
    bool? onlyActive,
    bool clearSearch = false,
    bool clearType = false,
  }) {
    return CustomersFilter(
      search: clearSearch ? null : (search ?? this.search),
      type: clearType ? null : (type ?? this.type),
      onlyActive: onlyActive ?? this.onlyActive,
    );
  }
}

final customersFilterProvider =
    StateProvider<CustomersFilter>((ref) => const CustomersFilter());

// =====================================================
// العملاء المفلترين
// =====================================================
final filteredCustomersProvider =
    FutureProvider.autoDispose<List<CustomerModel>>((ref) async {
  final repo = ref.watch(customersRepositoryProvider);
  final filter = ref.watch(customersFilterProvider);

  return await repo.getAllCustomers(
    onlyActive: filter.onlyActive,
    search: filter.search,
    type: filter.type,
  );
});

// =====================================================
// عميل واحد
// =====================================================
final customerByIdProvider =
    FutureProvider.autoDispose.family<CustomerModel?, String>((ref, id) async {
  final repo = ref.watch(customersRepositoryProvider);
  return await repo.getCustomerById(id);
});

// =====================================================
// Controller
// =====================================================
class CustomersController extends StateNotifier<AsyncValue<void>> {
  CustomersController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final CustomersRepository _repo;
  final Ref _ref;

  Future<bool> createCustomer(CustomerModel customer) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createCustomer(customer);
      state = const AsyncValue.data(null);
      _ref.invalidate(customersListProvider);
      _ref.invalidate(filteredCustomersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCustomer(customer);
      state = const AsyncValue.data(null);
      _ref.invalidate(customersListProvider);
      _ref.invalidate(filteredCustomersProvider);
      _ref.invalidate(customerByIdProvider(customer.id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCustomer(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(customersListProvider);
      _ref.invalidate(filteredCustomersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleStatus(String id, bool isActive) async {
    try {
      await _repo.toggleStatus(id, isActive);
      _ref.invalidate(customersListProvider);
      _ref.invalidate(filteredCustomersProvider);
      _ref.invalidate(customerByIdProvider(id));
      return true;
    } catch (e) {
      return false;
    }
  }
}

final customersControllerProvider =
    StateNotifierProvider<CustomersController, AsyncValue<void>>((ref) {
  return CustomersController(ref.read(customersRepositoryProvider), ref);
});

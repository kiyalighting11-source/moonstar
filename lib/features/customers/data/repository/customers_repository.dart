// lib/features/customers/data/repository/customers_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/customer_model.dart';

class CustomersRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CustomerModel>> getAllCustomers({
    bool onlyActive = false,
    String? search,
    String? type,
  }) async {
    var query = _supabase.from(AppConstants.customersTable).select('*');

    if (onlyActive) query = query.eq('is_active', true);
    if (type != null) query = query.eq('type', type);
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.or('name.ilike.%$q%,phone.ilike.%$q%,code.ilike.%$q%');
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final data = await _supabase
        .from(AppConstants.customersTable)
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return CustomerModel.fromJson(data);
  }

  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final userId = _supabase.auth.currentUser?.id;
    final data = await _supabase
        .from(AppConstants.customersTable)
        .insert({
          ...customer.toJson(),
          'created_by': userId,
        })
        .select('*')
        .single();

    return CustomerModel.fromJson(data);
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final data = await _supabase
        .from(AppConstants.customersTable)
        .update(customer.toJson())
        .eq('id', customer.id)
        .select('*')
        .single();

    return CustomerModel.fromJson(data);
  }

  Future<void> deleteCustomer(String id) async {
    await _supabase
        .from(AppConstants.customersTable)
        .update({'is_active': false}).eq('id', id);
  }

  Future<void> toggleStatus(String id, bool isActive) async {
    await _supabase
        .from(AppConstants.customersTable)
        .update({'is_active': isActive}).eq('id', id);
  }
}

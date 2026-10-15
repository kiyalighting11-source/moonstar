// lib/features/maintenance/data/repositories/maintenance_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/maintenance_device_model.dart';
import '../models/maintenance_model.dart';
import '../models/maintenance_part_model.dart';

class MaintenanceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _selectRelations = '''
    *,
    customers!customer_id (name, phone),
    technician:employees!technician_id (full_name),
    creator:profiles!created_by (full_name)
  ''';

  static const String _selectFull = '''
    *,
    customers!customer_id (name, phone),
    technician:employees!technician_id (full_name),
    creator:profiles!created_by (full_name),
    maintenance_devices (
      *,
      products!product_id (name, sku, main_image_url)
    ),
    maintenance_parts (
      *,
      products!product_id (name, sku, main_image_url)
    )
  ''';

  // =====================================================
  // QUERIES
  // =====================================================

  Future<List<MaintenanceModel>> getAllTickets({
    String? status,
    String? priority,
    String? technicianId,
    String? search,
    int limit = 200,
  }) async {
    var query = _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .select(_selectRelations);

    if (status != null) query = query.eq('status', status);
    if (priority != null) query = query.eq('priority', priority);
    if (technicianId != null) {
      query = query.eq('technician_id', technicianId);
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.or(
        'ticket_number.ilike.%$q%,notes.ilike.%$q%',
      );
    }

    final data = await query.order('created_at', ascending: false).limit(limit);

    return (data as List).map((e) => MaintenanceModel.fromJson(e)).toList();
  }

  Future<MaintenanceModel?> getTicketById(String id) async {
    final data = await _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .select(_selectFull)
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return MaintenanceModel.fromJson(data);
  }

  // =====================================================
  // CREATE / UPDATE / DELETE
  // =====================================================

  Future<MaintenanceModel> createTicket(MaintenanceModel ticket) async {
    final userId = _supabase.auth.currentUser?.id;

    final payload = <String, dynamic>{
      'customer_id': ticket.customerId,
      'technician_id': ticket.technicianId,
      'priority': ticket.priority,
      'status': ticket.status,
      'labor_cost': ticket.laborCost,
      'notes': ticket.notes,
      'created_by': userId,
      'received_at': DateTime.now().toIso8601String(),
      'parts_cost': 0,
      'total_cost': ticket.laborCost,
      'paid_amount': 0,
      'due_amount': ticket.laborCost,
    };

    if (ticket.expectedDelivery != null) {
      payload['expected_delivery'] =
          ticket.expectedDelivery!.toIso8601String().split('T').first;
    }

    final data = await _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .insert(payload)
        .select()
        .single();

    return MaintenanceModel.fromJson(data);
  }

  Future<MaintenanceModel> updateTicket(MaintenanceModel ticket) async {
    final payload = <String, dynamic>{
      'customer_id': ticket.customerId,
      'technician_id': ticket.technicianId,
      'priority': ticket.priority,
      'status': ticket.status,
      'labor_cost': ticket.laborCost,
      'notes': ticket.notes,
    };

    if (ticket.expectedDelivery != null) {
      payload['expected_delivery'] =
          ticket.expectedDelivery!.toIso8601String().split('T').first;
    } else {
      payload['expected_delivery'] = null;
    }

    final data = await _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .update(payload)
        .eq('id', ticket.id)
        .select()
        .single();

    // ⭐ إعادة حساب الإجمالي (ممكن labor_cost اتغير)
    await recalculateTicketTotals(ticket.id);

    return MaintenanceModel.fromJson(data);
  }

  Future<void> deleteTicket(String id) async {
    await _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .delete()
        .eq('id', id);
  }

  // =====================================================
  // UPDATE LABOR COST
  // =====================================================

  Future<void> updateLaborCost({
    required String ticketId,
    required double laborCost,
  }) async {
    debugPrint('🔧 updateLaborCost → ticket=$ticketId, value=$laborCost');

    await _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .update({'labor_cost': laborCost}).eq('id', ticketId);

    await recalculateTicketTotals(ticketId);
  }

  // =====================================================
  // STATUS
  // =====================================================

  Future<MaintenanceModel> updateStatus({
    required String id,
    required String status,
  }) async {
    final Map<String, dynamic> updates = {'status': status};

    if (status == 'delivered') {
      updates['delivered_at'] = DateTime.now().toIso8601String();
    }

    final data = await _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return MaintenanceModel.fromJson(data);
  }

  Future<MaintenanceModel> assignTechnician({
    required String id,
    required String? technicianId,
  }) async {
    final data = await _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .update({'technician_id': technicianId})
        .eq('id', id)
        .select()
        .single();

    return MaintenanceModel.fromJson(data);
  }

  // =====================================================
  // DEVICES
  // =====================================================

  Future<MaintenanceDeviceModel> addDevice({
    required String ticketId,
    String? productId,
    String? deviceDescription,
    String? serialNumber,
    required String issueDescription,
    String? resolution,
    double price = 0,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final payload = <String, dynamic>{
      'ticket_id': ticketId,
      'product_id': productId,
      'device_description': deviceDescription,
      'serial_number': serialNumber,
      'issue_description': issueDescription,
      'resolution': resolution,
      'price': price,
      'created_by': userId,
    };

    debugPrint('➕ addDevice → ticket=$ticketId, price=$price');

    final data = await _supabase
        .from('maintenance_devices')
        .insert(payload)
        .select()
        .single();

    await recalculateTicketTotals(ticketId);

    return MaintenanceDeviceModel.fromJson(data);
  }

  Future<MaintenanceDeviceModel> updateDevice(
    MaintenanceDeviceModel device,
  ) async {
    final payload = <String, dynamic>{
      'product_id': device.productId,
      'device_description': device.deviceDescription,
      'serial_number': device.serialNumber,
      'issue_description': device.issueDescription,
      'resolution': device.resolution,
      'price': device.price,
    };

    debugPrint(
      '✏️ updateDevice → id=${device.id}, ticket=${device.ticketId}, price=${device.price}',
    );

    final data = await _supabase
        .from('maintenance_devices')
        .update(payload)
        .eq('id', device.id)
        .select()
        .single();

    // ⭐ إعادة حساب الإجمالي بعد تعديل السعر
    await recalculateTicketTotals(device.ticketId);

    return MaintenanceDeviceModel.fromJson(data);
  }

  Future<void> deleteDevice(String deviceId, String ticketId) async {
    debugPrint('🗑️ deleteDevice → id=$deviceId, ticket=$ticketId');

    await _supabase.from('maintenance_devices').delete().eq('id', deviceId);

    await recalculateTicketTotals(ticketId);
  }

  Future<List<MaintenanceDeviceModel>> getTicketDevices(
    String ticketId,
  ) async {
    final data = await _supabase
        .from('maintenance_devices')
        .select('*, products!product_id (name, sku, main_image_url)')
        .eq('ticket_id', ticketId)
        .order('created_at');

    return (data as List)
        .map((e) => MaintenanceDeviceModel.fromJson(e))
        .toList();
  }

  // =====================================================
  // PARTS
  // =====================================================

  Future<MaintenancePartModel> addPart({
    required String ticketId,
    String? deviceId,
    required String productId,
    required double quantity,
    required double unitPrice,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final total = quantity * unitPrice;

    final payload = <String, dynamic>{
      'ticket_id': ticketId,
      'device_id': deviceId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'notes': notes,
      'created_by': userId,
    };

    final data = await _supabase
        .from(AppConstants.maintenancePartsTable)
        .insert(payload)
        .select()
        .single();

    await recalculateTicketTotals(ticketId);

    return MaintenancePartModel.fromJson(data);
  }

  Future<void> deletePart(String partId, String ticketId) async {
    await _supabase
        .from(AppConstants.maintenancePartsTable)
        .delete()
        .eq('id', partId);

    await recalculateTicketTotals(ticketId);
  }

  Future<List<MaintenancePartModel>> getTicketParts(
    String ticketId,
  ) async {
    final data = await _supabase
        .from(AppConstants.maintenancePartsTable)
        .select('*, products!product_id (name, sku, main_image_url)')
        .eq('ticket_id', ticketId)
        .order('created_at');

    return (data as List).map((e) => MaintenancePartModel.fromJson(e)).toList();
  }

  // =====================================================
  // PAYMENTS
  // =====================================================

  Future<List<Map<String, dynamic>>> getTicketPayments(
    String ticketId,
  ) async {
    final data = await _supabase
        .from(AppConstants.paymentsTable)
        .select('''
          *,
          creator:profiles!created_by (full_name)
        ''')
        .eq('maintenance_ticket_id', ticketId)
        .order('payment_date', ascending: false);

    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addPayment({
    required String ticketId,
    required double amount,
    required String method,
    DateTime? paymentDate,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from(AppConstants.paymentsTable).insert({
      'maintenance_ticket_id': ticketId,
      'invoice_id': null,
      'amount': amount,
      'method': method,
      'payment_date':
          (paymentDate ?? DateTime.now()).toIso8601String().split('T').first,
      'notes': notes,
      'created_by': userId,
    });

    await recalculateTicketTotals(ticketId);
  }

  // =====================================================
  // HELPERS - Cost Calculations
  // =====================================================

  /// ⭐ إجمالي أسعار الأجهزة في التذكرة
  Future<double> _calculateDevicesPrice(String ticketId) async {
    try {
      final data = await _supabase
          .from('maintenance_devices')
          .select('price')
          .eq('ticket_id', ticketId);

      double total = 0;
      for (final row in (data as List)) {
        final price = (row['price'] as num?)?.toDouble() ?? 0;
        total += price;
      }

      debugPrint(
        '💰 devicesPrice[$ticketId] = $total (${(data as List).length} devices)',
      );
      return total;
    } catch (e) {
      debugPrint('❌ _calculateDevicesPrice error: $e');
      return 0;
    }
  }

  /// ⭐ إجمالي تكلفة قطع الغيار
  Future<double> _calculatePartsCost(String ticketId) async {
    try {
      final data = await _supabase
          .from(AppConstants.maintenancePartsTable)
          .select('total')
          .eq('ticket_id', ticketId);

      double total = 0;
      for (final row in (data as List)) {
        total += (row['total'] as num?)?.toDouble() ?? 0;
      }

      debugPrint('💰 partsCost[$ticketId] = $total');
      return total;
    } catch (e) {
      debugPrint('❌ _calculatePartsCost error: $e');
      return 0;
    }
  }

  /// ⭐ إجمالي المدفوع
  Future<double> _calculatePaidAmount(String ticketId) async {
    try {
      final data = await _supabase
          .from(AppConstants.paymentsTable)
          .select('amount')
          .eq('maintenance_ticket_id', ticketId);

      double total = 0;
      for (final row in (data as List)) {
        total += (row['amount'] as num?)?.toDouble() ?? 0;
      }

      debugPrint('💰 paidAmount[$ticketId] = $total');
      return total;
    } catch (e) {
      debugPrint('❌ _calculatePaidAmount error: $e');
      return 0;
    }
  }

  /// ⭐⭐ الدالة الأساسية — بتحدّث الإجمالي في `maintenance_tickets`
  Future<void> recalculateTicketTotals(String ticketId) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔄 recalculateTicketTotals → ticket=$ticketId');

      // 1) نجيب labor_cost
      final ticketData = await _supabase
          .from(AppConstants.maintenanceTicketsTable)
          .select('labor_cost')
          .eq('id', ticketId)
          .maybeSingle();

      if (ticketData == null) {
        debugPrint('❌ ticket not found: $ticketId');
        return;
      }

      final laborCost = (ticketData['labor_cost'] as num?)?.toDouble() ?? 0;

      // 2) نحسب كل مكون
      final devicesPrice = await _calculateDevicesPrice(ticketId);
      final partsCost = await _calculatePartsCost(ticketId);
      final paidAmount = await _calculatePaidAmount(ticketId);

      // 3) الإجمالي = أجهزة + قطع + أجرة
      final totalCost = devicesPrice + partsCost + laborCost;
      final dueAmount = (totalCost - paidAmount).clamp(0, double.infinity);

      debugPrint(
        '📊 [$ticketId] devices=$devicesPrice + parts=$partsCost + labor=$laborCost = total=$totalCost',
      );
      debugPrint('📊 [$ticketId] paid=$paidAmount | due=$dueAmount');

      // 4) نحفظ
      await _supabase.from(AppConstants.maintenanceTicketsTable).update({
        'parts_cost': partsCost,
        'total_cost': totalCost,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'device_price': devicesPrice,
      }).eq('id', ticketId);

      debugPrint('✅ [$ticketId] total_cost=$totalCost SAVED');
      debugPrint('═══════════════════════════════════════');
    } catch (e, st) {
      debugPrint('❌ recalculateTicketTotals error: $e');
      debugPrint('📍 stack: $st');
    }
  }

  // =====================================================
  // STATS
  // =====================================================

  Future<Map<String, dynamic>> getStats() async {
    final data = await _supabase
        .from(AppConstants.maintenanceTicketsTable)
        .select('status, total_cost, due_amount, paid_amount');

    int total = 0;
    int newCount = 0;
    int inProgress = 0;
    int ready = 0;
    int delivered = 0;
    int cancelled = 0;
    double totalRevenue = 0;
    double totalDue = 0;
    double totalPaid = 0;

    for (final row in (data as List)) {
      total++;
      final status = row['status'] as String? ?? 'new';
      final totalCost = (row['total_cost'] as num?)?.toDouble() ?? 0;
      final dueAmount = (row['due_amount'] as num?)?.toDouble() ?? 0;
      final paidAmount = (row['paid_amount'] as num?)?.toDouble() ?? 0;

      totalRevenue += totalCost;
      totalDue += dueAmount;
      totalPaid += paidAmount;

      switch (status) {
        case 'new':
          newCount++;
          break;
        case 'diagnosing':
        case 'repairing':
        case 'waiting_parts':
          inProgress++;
          break;
        case 'ready':
          ready++;
          break;
        case 'delivered':
          delivered++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return {
      'total': total,
      'new': newCount,
      'in_progress': inProgress,
      'ready': ready,
      'delivered': delivered,
      'cancelled': cancelled,
      'total_revenue': totalRevenue,
      'total_due': totalDue,
      'total_paid': totalPaid,
    };
  }
}

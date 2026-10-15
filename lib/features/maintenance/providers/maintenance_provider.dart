// lib/features/maintenance/providers/maintenance_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/maintenance_device_model.dart';
import '../data/models/maintenance_model.dart';
import '../data/models/maintenance_part_model.dart';
import '../data/repositories/maintenance_repository.dart';

// =====================================================
// Repository
// =====================================================
final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository();
});

// =====================================================
// Filter
// =====================================================
class MaintenanceFilter {
  final String? status;
  final String? priority;
  final String? technicianId;
  final String? search;

  const MaintenanceFilter({
    this.status,
    this.priority,
    this.technicianId,
    this.search,
  });

  MaintenanceFilter copyWith({
    String? status,
    String? priority,
    String? technicianId,
    String? search,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearTechnician = false,
    bool clearSearch = false,
  }) {
    return MaintenanceFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      technicianId:
          clearTechnician ? null : (technicianId ?? this.technicianId),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

final maintenanceFilterProvider = StateProvider<MaintenanceFilter>((ref) {
  return const MaintenanceFilter();
});

// =====================================================
// Tickets List
// =====================================================
final maintenanceListProvider =
    FutureProvider.autoDispose<List<MaintenanceModel>>((ref) async {
  final repo = ref.watch(maintenanceRepositoryProvider);
  final filter = ref.watch(maintenanceFilterProvider);

  return await repo.getAllTickets(
    status: filter.status,
    priority: filter.priority,
    technicianId: filter.technicianId,
    search: filter.search,
  );
});

// =====================================================
// Single Ticket
// =====================================================
final maintenanceByIdProvider = FutureProvider.autoDispose
    .family<MaintenanceModel?, String>((ref, id) async {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return await repo.getTicketById(id);
});

// =====================================================
// Ticket Devices
// =====================================================
final maintenanceDevicesProvider = FutureProvider.autoDispose
    .family<List<MaintenanceDeviceModel>, String>((ref, ticketId) async {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return await repo.getTicketDevices(ticketId);
});

// =====================================================
// Ticket Parts
// =====================================================
final maintenancePartsProvider = FutureProvider.autoDispose
    .family<List<MaintenancePartModel>, String>((ref, ticketId) async {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return await repo.getTicketParts(ticketId);
});

// =====================================================
// Ticket Payments
// =====================================================
final maintenancePaymentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, ticketId) async {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return await repo.getTicketPayments(ticketId);
});

// =====================================================
// Stats
// =====================================================
final maintenanceStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return await repo.getStats();
});

// =====================================================
// Controller
// =====================================================
class MaintenanceController extends StateNotifier<AsyncValue<void>> {
  MaintenanceController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final MaintenanceRepository _repo;
  final Ref _ref;

  // =====================================================
  // TICKET
  // =====================================================

  Future<MaintenanceModel?> createTicket(MaintenanceModel ticket) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createTicket(ticket);
      state = const AsyncValue.data(null);
      _refresh();
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateTicket(MaintenanceModel ticket) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateTicket(ticket);
      state = const AsyncValue.data(null);
      _refresh(id: ticket.id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteTicket(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteTicket(id);
      state = const AsyncValue.data(null);
      _refresh();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateLaborCost({
    required String ticketId,
    required double laborCost,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateLaborCost(
        ticketId: ticketId,
        laborCost: laborCost,
      );
      state = const AsyncValue.data(null);
      _refresh(id: ticketId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateStatus({
    required String id,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateStatus(id: id, status: status);
      state = const AsyncValue.data(null);
      _refresh(id: id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> assignTechnician({
    required String id,
    required String? technicianId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.assignTechnician(id: id, technicianId: technicianId);
      state = const AsyncValue.data(null);
      _refresh(id: id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // =====================================================
  // DEVICES
  // =====================================================

  Future<bool> addDevice({
    required String ticketId,
    String? productId,
    String? deviceDescription,
    String? serialNumber,
    required String issueDescription,
    String? resolution,
    double price = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addDevice(
        ticketId: ticketId,
        productId: productId,
        deviceDescription: deviceDescription,
        serialNumber: serialNumber,
        issueDescription: issueDescription,
        resolution: resolution,
        price: price,
      );
      state = const AsyncValue.data(null);
      _refresh(id: ticketId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateDevice(MaintenanceDeviceModel device) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateDevice(device);
      state = const AsyncValue.data(null);
      _refresh(id: device.ticketId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteDevice({
    required String deviceId,
    required String ticketId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteDevice(deviceId, ticketId);
      state = const AsyncValue.data(null);
      _refresh(id: ticketId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // =====================================================
  // PARTS
  // =====================================================

  Future<bool> addPart({
    required String ticketId,
    String? deviceId,
    required String productId,
    required double quantity,
    required double unitPrice,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addPart(
        ticketId: ticketId,
        deviceId: deviceId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      _refresh(id: ticketId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deletePart({
    required String partId,
    required String ticketId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deletePart(partId, ticketId);
      state = const AsyncValue.data(null);
      _refresh(id: ticketId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // =====================================================
  // PAYMENTS
  // =====================================================

  Future<bool> addPayment({
    required String ticketId,
    required double amount,
    required String method,
    DateTime? paymentDate,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addPayment(
        ticketId: ticketId,
        amount: amount,
        method: method,
        paymentDate: paymentDate,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      _refresh(id: ticketId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // =====================================================
  // REFRESH
  // =====================================================

  void _refresh({String? id}) {
    _ref.invalidate(maintenanceListProvider);
    _ref.invalidate(maintenanceStatsProvider);
    if (id != null) {
      _ref.invalidate(maintenanceByIdProvider(id));
      _ref.invalidate(maintenanceDevicesProvider(id));
      _ref.invalidate(maintenancePartsProvider(id));
      _ref.invalidate(maintenancePaymentsProvider(id));
    }
  }
}

final maintenanceControllerProvider =
    StateNotifierProvider<MaintenanceController, AsyncValue<void>>((ref) {
  return MaintenanceController(
    ref.read(maintenanceRepositoryProvider),
    ref,
  );
});

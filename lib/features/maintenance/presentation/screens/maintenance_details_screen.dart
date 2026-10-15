// lib/features/maintenance/presentation/screens/maintenance_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../../printing/widgets/maintenance_pdf_action_sheet.dart';
import '../../data/models/maintenance_device_model.dart';
import '../../data/models/maintenance_model.dart';
import '../../data/models/maintenance_part_model.dart';
import '../../providers/maintenance_provider.dart';
import '../widgets/maintenance_device_form.dart';
import '../widgets/maintenance_part_form.dart';
import '../widgets/maintenance_payment_form.dart';
import '../widgets/maintenance_status_badge.dart';

class MaintenanceDetailsScreen extends ConsumerWidget {
  final String ticketId;

  const MaintenanceDetailsScreen({
    super.key,
    required this.ticketId,
  });

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(maintenanceByIdProvider(ticketId));
    ref.invalidate(maintenanceDevicesProvider(ticketId));
    ref.invalidate(maintenancePartsProvider(ticketId));
    ref.invalidate(maintenancePaymentsProvider(ticketId));
    ref.invalidate(maintenanceListProvider);
    ref.invalidate(maintenanceStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(maintenanceByIdProvider(ticketId));
    final roleCode = ref.watch(currentRoleProvider);
    final canEdit = roleCode == AppConstants.roleAdmin ||
        roleCode == AppConstants.roleManager;

    return ticketAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        appBar: DashboardAppBar(
          title: 'تفاصيل التذكرة',
          actions: [ThemeToggleButton()],
        ),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const DashboardAppBar(
          title: 'تفاصيل التذكرة',
          actions: [ThemeToggleButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ),
      ),
      data: (ticket) {
        if (ticket == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: const DashboardAppBar(
              title: 'تفاصيل التذكرة',
              actions: [ThemeToggleButton()],
            ),
            body: Center(
              child: Text(
                'التذكرة غير موجودة',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: DashboardAppBar(
            title: 'تفاصيل التذكرة',
            actions: [
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'طباعة / مشاركة',
                onPressed: () => _showPdfActions(context, ticket),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _refreshAll(ref),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'تعديل التذكرة',
                  onPressed: () => context.go('/maintenance/edit/$ticketId'),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _refreshAll(ref);
              await ref.read(maintenanceByIdProvider(ticketId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, ticket),
                const SizedBox(height: 16),
                _buildCustomerSection(context, ticket),
                const SizedBox(height: 12),
                _buildDevicesSection(context, ref, ticket, canEdit),
                const SizedBox(height: 12),
                _buildTechnicianSection(context, ref, ticket, canEdit),
                const SizedBox(height: 12),
                _buildLaborCostSection(context, ref, ticket, canEdit),
                const SizedBox(height: 12),
                _buildTotalsSection(context, ticket),
                const SizedBox(height: 12),
                _buildPaymentsSection(context, ref, ticket, canEdit),
                const SizedBox(height: 12),
                _buildStatusActions(context, ref, ticket, canEdit),
                if (ticket.notes != null && ticket.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildNotesSection(context, ticket),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // PDF Actions
  // =====================================================
  void _showPdfActions(BuildContext context, MaintenanceModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenancePdfActionSheet(ticket: ticket),
    );
  }

  // =====================================================
  // Header
  // =====================================================
  Widget _buildHeader(BuildContext context, MaintenanceModel ticket) {
    final statusColor = _statusColor(ticket.status);
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(ticket.status),
                  color: statusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.ticketNumber,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatDateTime(ticket.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              MaintenanceStatusBadge(status: ticket.status),
              const SizedBox(width: 8),
              MaintenancePriorityBadge(priority: ticket.priority),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Customer Section
  // =====================================================
  Widget _buildCustomerSection(BuildContext context, MaintenanceModel t) {
    return _section(context, 'العميل', [
      _row(context, Icons.person, 'الاسم', t.customerName ?? '—'),
      if (t.customerPhone != null)
        _row(context, Icons.phone, 'الموبايل', t.customerPhone!),
    ]);
  }

  // =====================================================
  // Devices Section
  // =====================================================
  Widget _buildDevicesSection(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
    bool canEdit,
  ) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'الأجهزة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${t.devicesCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              if (canEdit)
                TextButton.icon(
                  onPressed: () => _showAddDeviceSheet(context, ref, t.id),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'إضافة جهاز',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (t.devices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'مفيش أجهزة مضافة',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...t.devices.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _deviceCard(context, ref, d, t, canEdit),
                )),
        ],
      ),
    );
  }

  Widget _deviceCard(
    BuildContext context,
    WidgetRef ref,
    MaintenanceDeviceModel device,
    MaintenanceModel ticket,
    bool canEdit,
  ) {
    final isDark = AppTheme.isDark(context);

    final deviceParts =
        ticket.parts.where((p) => p.deviceId == device.id).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppTheme.lightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.build_circle,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    if (device.hasSerial) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Serial: ${device.serialNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (device.price > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    Helpers.formatCurrency(device.price, decimals: 0),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
              if (canEdit)
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                    color: AppTheme.infoColor,
                  ),
                  tooltip: 'تعديل الجهاز',
                  onPressed: () => _showEditDeviceSheet(
                    context,
                    ref,
                    device,
                    ticket,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
              if (canEdit)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppTheme.errorColor,
                  ),
                  tooltip: 'حذف الجهاز',
                  onPressed: () =>
                      _deleteDevice(context, ref, device, ticket.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
            ],
          ),

          // Placeholder للسعر
          if (device.price == 0 && canEdit) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showEditDeviceSheet(
                context,
                ref,
                device,
                ticket,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: AppTheme.warningColor,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'اضغط لإضافة سعر الجهاز',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      size: 12,
                      color: AppTheme.warningColor,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Issue
          if (device.issueDescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            _issueRow(
              context,
              Icons.report_problem_outlined,
              'المشكلة',
              device.issueDescription,
              AppTheme.errorColor,
            ),
          ],

          // Resolution
          if (device.resolution != null && device.resolution!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _issueRow(
              context,
              Icons.check_circle_outline,
              'اللي اتعمل',
              device.resolution!,
              AppTheme.successColor,
            ),
          ] else if (canEdit) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showEditDeviceSheet(
                context,
                ref,
                device,
                ticket,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.infoColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      size: 14,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'اضغط لإضافة "اللي اتعمل"',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.infoColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Parts
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.build_circle,
                      size: 14,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'قطع الغيار (${deviceParts.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const Spacer(),
                    if (canEdit)
                      TextButton.icon(
                        onPressed: () => _showAddPartSheet(
                          context,
                          ref,
                          ticket.id,
                          device.id,
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'إضافة',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (deviceParts.isEmpty)
                  Text(
                    'مفيش قطع غيار',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  )
                else
                  ...deviceParts.map(
                    (p) => _devicePartRow(
                      context,
                      ref,
                      p,
                      ticket.id,
                      canEdit,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _devicePartRow(
    BuildContext context,
    WidgetRef ref,
    MaintenancePartModel part,
    String ticketId,
    bool canEdit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.infoColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.productName ?? 'قطعة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
                Text(
                  '${part.quantity.toStringAsFixed(0)} × '
                  '${Helpers.formatCurrency(part.unitPrice, decimals: 0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                if (part.notes != null && part.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      part.notes!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Helpers.formatCurrency(part.total, decimals: 0),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.infoColor,
            ),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 14,
                color: AppTheme.errorColor,
              ),
              onPressed: () => _deletePart(context, ref, part, ticketId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _issueRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Technician Section
  // =====================================================
  Widget _buildTechnicianSection(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
    bool canEdit,
  ) {
    return _section(context, 'الفني المسؤول', [
      if (t.hasTechnician)
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.infoColor.withValues(alpha: 0.15),
              child: Text(
                Helpers.initials(t.technicianName ?? '?'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.infoColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.technicianName ?? '—',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: () => _showAssignTechnicianDialog(context, ref, t),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('تغيير'),
              ),
          ],
        )
      else
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: AppTheme.warningColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'لم يتم تعيين فني',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningColor,
                ),
              ),
            ),
            if (canEdit)
              ElevatedButton.icon(
                onPressed: () => _showAssignTechnicianDialog(context, ref, t),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('تعيين'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
    ]);
  }

  // =====================================================
  // Labor Cost Section
  // =====================================================
  Widget _buildLaborCostSection(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
    bool canEdit,
  ) {
    return _section(context, 'أجرة الصيانة', [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.build,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أجرة الصيانة',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Helpers.formatCurrency(t.laborCost, decimals: 0),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (canEdit)
            TextButton.icon(
              onPressed: () => _showEditLaborCostSheet(context, ref, t),
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('تعديل'),
            ),
        ],
      ),
    ]);
  }

  // =====================================================
  // Totals Section
  // =====================================================
  Widget _buildTotalsSection(
    BuildContext context,
    MaintenanceModel t,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          if (t.devicesPrice > 0)
            _totalRow(
              context,
              'الأجهزة (${t.devicesCount})',
              t.devicesPrice,
              Colors.white70,
            ),
          if (t.partsCost > 0)
            _totalRow(
              context,
              'قطع الغيار (${t.partsCount})',
              t.partsCost,
              Colors.white70,
            ),
          if (t.laborCost > 0)
            _totalRow(
              context,
              'أجرة الصيانة',
              t.laborCost,
              Colors.white70,
            ),
          if (t.devicesPrice == 0 && t.partsCost == 0 && t.laborCost == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'مفيش تكاليف مضافة',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          const Divider(color: Colors.white30, height: 20),
          _totalRow(
            context,
            'الإجمالي',
            t.totalCost,
            Colors.white,
            bold: true,
            big: true,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _smallStat(
                  context,
                  'المدفوع',
                  t.paidAmount,
                  Colors.green.shade200,
                ),
              ),
              Expanded(
                child: _smallStat(
                  context,
                  'المتبقي',
                  t.dueAmount,
                  t.dueAmount > 0 ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    double value,
    Color color, {
    bool bold = false,
    bool big = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: big ? 16 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            Helpers.formatCurrency(value, decimals: 0),
            style: TextStyle(
              color: color,
              fontSize: big ? 20 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStat(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              Helpers.formatCurrency(value, decimals: 0),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Payments Section
  // =====================================================
  Widget _buildPaymentsSection(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
    bool canEdit,
  ) {
    final paymentsAsync = ref.watch(maintenancePaymentsProvider(t.id));

    return _section(context, 'الدفعات', [
      paymentsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text(
          'خطأ: $e',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return Text(
              'مفيش دفعات لسه',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
              ),
            );
          }

          return Column(
            children: payments.map((p) => _paymentTile(context, p)).toList(),
          );
        },
      ),
      if (canEdit && t.dueAmount > 0 && t.status != 'cancelled') ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () => _showAddPaymentSheet(context, ref, t),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة دفعة'),
          ),
        ),
      ],
    ]);
  }

  Widget _paymentTile(
    BuildContext context,
    Map<String, dynamic> payment,
  ) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final method = payment['method'] as String? ?? 'cash';
    final dateStr = payment['payment_date'] as String?;
    final notes = payment['notes'] as String?;
    final creator = payment['creator'];

    DateTime? date;
    try {
      date = dateStr != null ? DateTime.parse(dateStr) : null;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments,
                size: 16,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Helpers.formatCurrency(amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
              Text(
                AppConstants.paymentMethodAr[method] ?? method,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 11,
                color: AppTheme.textSecondaryColor(context),
              ),
              const SizedBox(width: 4),
              Text(
                date != null ? Helpers.formatDate(date) : '—',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              if (creator is Map && creator['full_name'] != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.person,
                  size: 11,
                  color: AppTheme.textSecondaryColor(context),
                ),
                const SizedBox(width: 4),
                Text(
                  creator['full_name'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              notes,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // Status Actions
  // =====================================================
  Widget _buildStatusActions(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
    bool canEdit,
  ) {
    if (!canEdit) return const SizedBox.shrink();

    final transitions = _statusTransitions(t.status);
    if (transitions.isEmpty) return const SizedBox.shrink();

    return _section(context, 'الإجراءات', [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: transitions.map((s) {
          return ElevatedButton.icon(
            onPressed: () => _updateStatus(context, ref, t, s.value),
            icon: Icon(s.icon, size: 16),
            label: Text(s.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: s.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  List<_StatusTransition> _statusTransitions(String current) {
    switch (current) {
      case 'new':
        return const [
          _StatusTransition(
            'waiting_parts',
            'في انتظار قطع',
            Icons.hourglass_empty,
            Color(0xFFE53935),
          ),
          _StatusTransition(
            'ready',
            'تمت',
            Icons.check_circle_outline,
            Color(0xFF00ACC1),
          ),
          _StatusTransition(
            'cancelled',
            'إلغاء',
            Icons.cancel,
            Colors.grey,
          ),
        ];
      case 'waiting_parts':
        return const [
          _StatusTransition(
            'ready',
            'تمت',
            Icons.check_circle_outline,
            Color(0xFF00ACC1),
          ),
          _StatusTransition(
            'cancelled',
            'إلغاء',
            Icons.cancel,
            Colors.grey,
          ),
        ];
      case 'ready':
        return const [
          _StatusTransition(
            'delivered',
            'تم التسليم',
            Icons.check_circle,
            Color(0xFF43A047),
          ),
        ];
      default:
        return const [];
    }
  }

  // =====================================================
  // Notes Section
  // =====================================================
  Widget _buildNotesSection(
    BuildContext context,
    MaintenanceModel t,
  ) {
    return _section(context, 'ملاحظات', [
      Text(
        t.notes!,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondaryColor(context),
          height: 1.7,
        ),
      ),
    ]);
  }

  // =====================================================
  // Helpers
  // =====================================================
  Widget _section(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = AppTheme.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondaryColor(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return AppTheme.infoColor;
      case 'diagnosing':
        return const Color(0xFF7E57C2);
      case 'repairing':
        return const Color(0xFFFB8C00);
      case 'waiting_parts':
        return AppTheme.errorColor;
      case 'ready':
        return const Color(0xFF00ACC1);
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'new':
        return Icons.fiber_new;
      case 'diagnosing':
        return Icons.search;
      case 'repairing':
        return Icons.build;
      case 'waiting_parts':
        return Icons.hourglass_empty;
      case 'ready':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // =====================================================
  // Actions
  // =====================================================
  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
    String newStatus,
  ) async {
    final confirmed = await Helpers.confirmDialog(
      context,
      title: 'تغيير الحالة',
      message:
          'تغيير الحالة إلى "${AppConstants.maintStatusAr[newStatus] ?? newStatus}"؟',
      confirmText: 'تأكيد',
    );

    if (!confirmed) return;

    final success = await ref
        .read(maintenanceControllerProvider.notifier)
        .updateStatus(id: t.id, status: newStatus);

    if (!context.mounted) return;
    if (success) {
      Helpers.showSuccess(context, 'تم تحديث الحالة');
    } else {
      final error = ref.read(maintenanceControllerProvider).error;
      Helpers.showError(context, 'فشل التحديث: $error');
    }
  }

  // =====================================================
  // Edit Labor Cost Sheet
  // =====================================================
  Future<void> _showEditLaborCostSheet(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
  ) async {
    final controller = TextEditingController(
      text: t.laborCost.toStringAsFixed(0),
    );
    final isDark = AppTheme.isDark(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151A23) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.build,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تعديل أجرة الصيانة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'أجرة الصيانة',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'ج.م',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final value = Helpers.parseDouble(controller.text);

                    Navigator.pop(sheetContext);

                    final success = await ref
                        .read(maintenanceControllerProvider.notifier)
                        .updateLaborCost(
                          ticketId: t.id,
                          laborCost: value,
                        );

                    if (!context.mounted) return;
                    if (success) {
                      _refreshAll(ref);
                      Helpers.showSuccess(context, 'تم تحديث الأجرة');
                    } else {
                      Helpers.showError(context, 'فشل التحديث');
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('حفظ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Edit Device Sheet
  // =====================================================
  Future<void> _showEditDeviceSheet(
    BuildContext context,
    WidgetRef ref,
    MaintenanceDeviceModel device,
    MaintenanceModel ticket,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenanceDeviceForm(
        ticketId: ticket.id,
        deviceId: device.id,
      ),
    );

    if (result == true) {
      _refreshAll(ref);
    }
  }

  Future<void> _showAddDeviceSheet(
    BuildContext context,
    WidgetRef ref,
    String ticketId,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenanceDeviceForm(ticketId: ticketId),
    );

    if (result == true) {
      _refreshAll(ref);
    }
  }

  Future<void> _showAddPartSheet(
    BuildContext context,
    WidgetRef ref,
    String ticketId,
    String deviceId,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenancePartForm(
        ticketId: ticketId,
        deviceId: deviceId,
      ),
    );

    if (result == true) {
      _refreshAll(ref);
    }
  }

  Future<void> _showAddPaymentSheet(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenancePaymentForm(
        ticketId: t.id,
        maxAmount: t.dueAmount,
      ),
    );

    if (result == true) {
      _refreshAll(ref);
    }
  }

  Future<void> _deleteDevice(
    BuildContext context,
    WidgetRef ref,
    MaintenanceDeviceModel device,
    String ticketId,
  ) async {
    final confirmed = await Helpers.confirmDialog(
      context,
      title: 'حذف الجهاز',
      message: 'حذف "${device.displayName}" وكل قطعه؟',
      confirmText: 'حذف',
      confirmColor: AppTheme.errorColor,
    );

    if (!confirmed) return;

    final success =
        await ref.read(maintenanceControllerProvider.notifier).deleteDevice(
              deviceId: device.id,
              ticketId: ticketId,
            );

    if (!context.mounted) return;
    if (success) {
      _refreshAll(ref);
      Helpers.showSuccess(context, 'تم حذف الجهاز');
    } else {
      Helpers.showError(context, 'فشل الحذف');
    }
  }

  Future<void> _deletePart(
    BuildContext context,
    WidgetRef ref,
    MaintenancePartModel part,
    String ticketId,
  ) async {
    final confirmed = await Helpers.confirmDialog(
      context,
      title: 'حذف القطعة',
      message: 'حذف "${part.productName}"؟',
      confirmText: 'حذف',
      confirmColor: AppTheme.errorColor,
    );

    if (!confirmed) return;

    final success = await ref
        .read(maintenanceControllerProvider.notifier)
        .deletePart(partId: part.id, ticketId: ticketId);

    if (!context.mounted) return;
    if (success) {
      _refreshAll(ref);
      Helpers.showSuccess(context, 'تم الحذف');
    } else {
      Helpers.showError(context, 'فشل الحذف');
    }
  }

  void _showAssignTechnicianDialog(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel t,
  ) {
    final employeesAsync = ref.read(employeesListProvider);
    final isDark = AppTheme.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return employeesAsync.when(
          loading: () => const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => AlertDialog(
            content: Text('خطأ: $e'),
          ),
          data: (employees) {
            final active = employees.where((e) => e.isActive).toList();

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF151A23) : Colors.white,
              title: const Text('تعيين فني'),
              content: SizedBox(
                width: 400,
                child: Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: active.length,
                    itemBuilder: (_, i) {
                      final emp = active[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          child: Text(
                            Helpers.initials(emp.fullName),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        title: Text(emp.fullName),
                        subtitle: Text(emp.employeeCode),
                        selected: t.technicianId == emp.id,
                        onTap: () async {
                          Navigator.pop(ctx);

                          final success = await ref
                              .read(
                                maintenanceControllerProvider.notifier,
                              )
                              .assignTechnician(
                                id: t.id,
                                technicianId: emp.id,
                              );

                          if (!context.mounted) return;
                          if (success) {
                            Helpers.showSuccess(
                              context,
                              'تم تعيين ${emp.fullName}',
                            );
                          } else {
                            Helpers.showError(context, 'فشل التعيين');
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// =====================================================
// Models (Options)
// =====================================================
class _StatusTransition {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatusTransition(
    this.value,
    this.label,
    this.icon,
    this.color,
  );
}

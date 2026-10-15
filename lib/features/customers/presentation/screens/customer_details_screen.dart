// lib/features/customers/presentation/screens/customer_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../data/models/customer_model.dart';
import '../../data/providers/customers_provider.dart';
import '../widgets/customer_invoices_section.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));
    final isLoggedIn = AuthGuard.isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'تفاصيل العميل',
        actions: isLoggedIn
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.go('/customers/edit/$customerId'),
                ),
              ]
            : null,
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'حدث خطأ: $e',
            style: TextStyle(color: AppTheme.textColor(context)),
          ),
        ),
        data: (customer) {
          if (customer == null) {
            return Center(
              child: Text(
                'العميل غير موجود',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
            );
          }
          return _buildContent(context, customer);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, CustomerModel customer) {
    final isDark = AppTheme.isDark(context);
    final typeColor =
        customer.isCompany ? AppTheme.infoColor : AppTheme.primaryColor;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // الهيدر
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151A23) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow(context),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: typeColor.withValues(alpha: 0.15),
                  child: Text(
                    Helpers.initials(customer.name),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  customer.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.code,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(customer.isCompany ? 'شركة' : 'فرد'),
                  backgroundColor: typeColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // الرصيد
          if (customer.hasBalance)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (customer.balance > 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor)
                    .withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (customer.balance > 0
                          ? AppTheme.errorColor
                          : AppTheme.successColor)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: customer.balance > 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.balance > 0 ? 'مدين' : 'دائن',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(customer.balance),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: customer.balance > 0
                              ? AppTheme.errorColor
                              : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // البيانات
          _section(context, 'بيانات الاتصال', [
            _infoRow(context, Icons.phone_outlined, 'الموبايل', customer.phone),
            _infoRow(context, Icons.phone_android, 'موبايل 2', customer.phone2),
            _infoRow(context, Icons.email_outlined, 'الإيميل', customer.email),
            _infoRow(context, Icons.location_on_outlined, 'العنوان',
                customer.address),
            if (customer.isCompany)
              _infoRow(context, Icons.receipt_outlined, 'الرقم الضريبي',
                  customer.taxNumber),
          ]),

          if (customer.notes != null && customer.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section(context, 'ملاحظات', [
              Text(
                customer.notes!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textColor(context),
                ),
              ),
            ]),
          ],

          // الفواتير
          const SizedBox(height: 16),
          CustomerInvoicesSection(customerId: customerId),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final isDark = AppTheme.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value,
  ) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondaryColor(context)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/features/customers/presentation/widgets/customer_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback? onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final typeColor =
        customer.isCompany ? AppTheme.infoColor : AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A23) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            // الأفاتار
            CircleAvatar(
              radius: 24,
              backgroundColor: typeColor.withValues(alpha: 0.15),
              child: Text(
                Helpers.initials(customer.name),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // البيانات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ),
                      if (!customer.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'متوقف',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 12,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.code,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                      if (customer.phone != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // الرصيد
            if (customer.hasBalance)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Helpers.formatCurrency(customer.balance, decimals: 0),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: customer.balance > 0
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.balance > 0 ? 'مدين' : 'دائن',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

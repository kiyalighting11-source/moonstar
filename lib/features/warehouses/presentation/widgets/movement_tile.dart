// lib/features/warehouses/presentation/widgets/movement_tile.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/stock_movement_model.dart';

class MovementTile extends StatelessWidget {
  final StockMovementModel movement;

  const MovementTile({super.key, required this.movement});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          // الأيقونة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIcon(),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // البيانات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.productName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  movement.typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Helpers.formatDateTime(movement.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),

          // الكمية
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${movement.isIn ? '+' : '-'}${movement.quantity.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (movement.balanceAfter != null) ...[
                const SizedBox(height: 2),
                Text(
                  'الرصيد: ${movement.balanceAfter!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (movement.isIn) return AppTheme.successColor;
    if (movement.isOut) return AppTheme.errorColor;
    return AppTheme.warningColor;
  }

  IconData _getIcon() {
    switch (movement.type) {
      case 'purchase_in':
        return Icons.arrow_downward;
      case 'sale_out':
        return Icons.arrow_upward;
      case 'transfer_in':
        return Icons.login;
      case 'transfer_out':
        return Icons.logout;
      case 'adjustment':
        return Icons.tune;
      case 'maintenance_out':
        return Icons.build;
      case 'return_in':
        return Icons.assignment_return;
      case 'return_out':
        return Icons.assignment_return_outlined;
      default:
        return Icons.swap_horiz;
    }
  }
}

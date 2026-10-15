// lib/features/products/presentation/widgets/product_status_badge.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProductStatusBadge extends StatelessWidget {
  final bool isActive;

  const ProductStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.successColor : AppTheme.errorColor;
    final label = isActive ? 'نشط' : 'متوقف';
    final icon = isActive ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

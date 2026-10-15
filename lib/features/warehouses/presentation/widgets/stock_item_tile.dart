// lib/features/warehouses/presentation/widgets/stock_item_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/stock_model.dart';

class StockItemTile extends StatelessWidget {
  final StockModel stock;
  final VoidCallback? onTap;

  const StockItemTile({
    super.key,
    required this.stock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final color = _getQuantityColor();

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
            // الصورة
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: _buildImage(context),
              ),
            ),
            const SizedBox(width: 12),

            // البيانات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.productName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stock.productSku ?? '',
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
                  stock.quantity.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (stock.productImageUrl == null || stock.productImageUrl!.isEmpty) {
      return Container(
        color: AppTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.lightBg,
        child: Icon(
          Icons.image_outlined,
          color: AppTheme.textSecondaryColor(context),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: stock.productImageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: AppTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.lightBg,
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.lightBg,
        child: Icon(
          Icons.broken_image_outlined,
          color: AppTheme.textSecondaryColor(context),
        ),
      ),
    );
  }

  Color _getQuantityColor() {
    if (stock.quantity <= 0) return AppTheme.errorColor;
    if (stock.isLowStock) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String _getStatusLabel() {
    if (stock.quantity <= 0) return 'ناقص';
    if (stock.isLowStock) return 'قليل';
    return 'متوفر';
  }
}

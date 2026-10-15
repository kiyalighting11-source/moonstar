// lib/features/products/presentation/widgets/product_list_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/product_model.dart';

class ProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final imageCount = _countImages(product);
    final hasVideo = product.videoUrl != null && product.videoUrl!.isNotEmpty;

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
            // ⭐ الصورة + المؤشرات
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _buildImage(context),
                  ),
                ),

                // مؤشر الفيديو
                if (hasVideo)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),

                // مؤشر عدد الصور
                if (imageCount > 1)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$imageCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
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
                        product.sku,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  if (product.categoryName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.categoryName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Helpers.formatCurrency(product.price, decimals: 0),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (!product.isActive)
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
          ],
        ),
      ),
    );
  }

  int _countImages(ProductModel product) {
    int count = 0;
    if (product.mainImageUrl != null && product.mainImageUrl!.isNotEmpty) {
      count++;
    }
    count += product.galleryImages.where((url) => url.isNotEmpty).length;
    return count;
  }

  Widget _buildImage(BuildContext context) {
    if (product.mainImageUrl == null || product.mainImageUrl!.isEmpty) {
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
      imageUrl: product.mainImageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.lightBg,
      ),
      errorWidget: (context, url, error) => Container(
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
}

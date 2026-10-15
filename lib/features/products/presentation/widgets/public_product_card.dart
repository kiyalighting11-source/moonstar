// lib/features/products/presentation/widgets/public_product_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../data/models/product_model.dart';

class PublicProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const PublicProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<PublicProductCard> createState() => _PublicProductCardState();
}

class _PublicProductCardState extends State<PublicProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isWeb = ResponsiveHelper.isWeb(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return MouseRegion(
      onEnter: isWeb ? (_) => setState(() => _isHovered = true) : null,
      onExit: isWeb ? (_) => setState(() => _isHovered = false) : null,
      cursor: isWeb ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            0,
            _isHovered ? -4 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151A23) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // الصورة
              // =====================================================
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(context),

                      // مؤشر الفيديو
                      if (widget.product.videoUrl != null &&
                          widget.product.videoUrl!.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'فيديو',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Hover overlay
                      if (_isHovered)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // =====================================================
              // المعلومات (بدون سعر)
              // =====================================================
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // الاسم
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: AppTheme.textColor(context),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ⭐ بدل السعر: زر "اعرف المزيد"
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.categoryName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                          ),
                          if (_isHovered && isWeb)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 14,
                              ),
                            )
                          else
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (widget.product.mainImageUrl == null ||
        widget.product.mainImageUrl!.isEmpty) {
      return Container(
        color: AppTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF5F5F7),
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.product.mainImageUrl!,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => Container(
        color: AppTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF5F5F7),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF5F5F7),
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

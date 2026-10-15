// lib/features/landing/presentation/widgets/gallery_section.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/scroll_animations.dart';

class GallerySection extends StatefulWidget {
  const GallerySection({super.key});

  @override
  State<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<GallerySection>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _hoveredIndex = -1;

  // =====================================================
  // المنتجات (8 تصنيفات مختلفة)
  // =====================================================
  static final List<_GalleryItem> _items = [
    _GalleryItem(
      name: 'LED Screen',
      category: 'شاشات',
      icon: Icons.tv,
      color: const Color(0xFF6A1B9A),
      imageUrl: 'assets/images/bg_1.jpg',
    ),
    _GalleryItem(
      name: 'Beam Moving Head',
      category: 'إضاءة مسرح',
      icon: Icons.flash_on,
      color: const Color(0xFF00ACC1),
      imageUrl: 'assets/images/bg_2.jpg',
    ),
    _GalleryItem(
      name: 'Par Light',
      category: 'إضاءة',
      icon: Icons.flashlight_on,
      color: const Color(0xFFFFB300),
      imageUrl: 'assets/images/bg_3.jpg',
    ),
    _GalleryItem(
      name: 'Aluminum Truss',
      category: 'تراس',
      icon: Icons.view_module,
      color: const Color(0xFF43A047),
      imageUrl: 'assets/images/bg_4.jpg',
    ),
    _GalleryItem(
      name: 'Laser Light',
      category: 'إضاءة مسرح',
      icon: Icons.graphic_eq,
      color: const Color(0xFFE53935),
      imageUrl: 'assets/images/bg_1.jpg',
    ),
    _GalleryItem(
      name: 'Smoke Machine',
      category: 'معدات',
      icon: Icons.cloud,
      color: const Color(0xFF7E57C2),
      imageUrl: 'assets/images/bg_2.jpg',
    ),
    _GalleryItem(
      name: 'Console',
      category: 'تحكم',
      icon: Icons.dashboard,
      color: const Color(0xFF1E88E5),
      imageUrl: 'assets/images/bg_3.jpg',
    ),
    _GalleryItem(
      name: 'Stage',
      category: 'مسرح',
      icon: Icons.stadium,
      color: const Color(0xFFFB8C00),
      imageUrl: 'assets/images/bg_4.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getHorizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isMobile ? 60 : 100,
      ),
      color: Colors.transparent,
      child: Column(
        children: [
          // Header
          FadeInOnScroll(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.grid_view,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'معرض الأعمال',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تصفح منتجاتنا',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 42,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColor(context),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Text(
                    'مجموعة مختارة من منتجاتنا عبر مختلف التصنيفات',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: AppTheme.textSecondaryColor(context),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // 3D Carousel
          SizedBox(
            height: isMobile ? 320 : 400,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, _) {
                return _build3DCarousel(context, isMobile);
              },
            ),
          ),

          const SizedBox(height: 40),

          // زرار "تصفح كل المنتجات"
          FadeInOnScroll(
            child: ElevatedButton.icon(
              onPressed: () => context.go('/shop'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                'تصفح كل المنتجات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 36,
                  vertical: isMobile ? 16 : 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 8,
                shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 3D Carousel
  // =====================================================
  Widget _build3DCarousel(BuildContext context, bool isMobile) {
    final count = _items.length;
    final radius = isMobile ? 160.0 : 240.0;
    final cardWidth = isMobile ? 140.0 : 200.0;
    final cardHeight = isMobile ? 200.0 : 280.0;

    final angleStep = (2 * math.pi) / count;

    return Stack(
      alignment: Alignment.center,
      children: List.generate(count, (index) {
        return AnimatedBuilder(
          animation: _rotationController,
          builder: (context, _) {
            // زاوية الكارت الحالي (بتلف مع الوقت)
            final angle =
                (_rotationController.value * 2 * math.pi) + (index * angleStep);

            // موقع الكارت على الدايرة
            final x = math.cos(angle) * radius;
            final z = math.sin(angle) * radius;

            // عمق الكارت (1 = قريب، 0 = بعيد)
            final depth = (z + radius) / (2 * radius);

            // شفافية الكارت
            final opacity = 0.4 + (depth * 0.6);

            // حجم الكارت
            final scale = 0.6 + (depth * 0.4);

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..translateByDouble(x, 0.0, z, 1.0)
                ..scaleByDouble(scale, scale, scale, 1.0),
              child: Opacity(
                opacity: opacity,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = -1),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/shop'),
                    child: _buildCard(
                      context,
                      _items[index],
                      width: cardWidth,
                      height: cardHeight,
                      isHovered: _hoveredIndex == index,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // =====================================================
  // Card
  // =====================================================
  Widget _buildCard(
    BuildContext context,
    _GalleryItem item, {
    required double width,
    required double height,
    required bool isHovered,
  }) {
    final isDark = AppTheme.isDark(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHovered ? item.color : item.color.withValues(alpha: 0.3),
          width: isHovered ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: isHovered ? 0.5 : 0.25),
            blurRadius: isHovered ? 30 : 15,
            spreadRadius: isHovered ? 5 : 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الخلفية (صورة أو gradient)
            _buildCardImage(context, item),

            // Overlay داكن
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // الأيقونة (فوق)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
            ),

            // المعلومات (تحت)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // التصنيف
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // الاسم
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hover overlay
            if (isHovered)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(BuildContext context, _GalleryItem item) {
    return Image.asset(
      item.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.color,
              item.color.withValues(alpha: 0.6),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Model
// =====================================================
class _GalleryItem {
  final String name;
  final String category;
  final IconData icon;
  final Color color;
  final String imageUrl;

  _GalleryItem({
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    required this.imageUrl,
  });
}

// lib/features/products/presentation/product_details_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_guard.dart';
import '../../../core/utils/helpers.dart';
import '../data/models/product_model.dart';
import '../providers/products_provider.dart';
import 'widgets/product_info_row.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = AuthGuard.isLoggedIn;

    // ⭐ المسجل → من products (بالأسعار)
    // ⭐ الزائر → من public_products (بدون أسعار)
    final productAsync = isLoggedIn
        ? ref.watch(productByIdProvider(productId))
        : ref.watch(publicProductByIdProvider(productId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: productAsync.when(
        loading: () => const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ: $e',
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => isLoggedIn
                      ? ref.invalidate(productByIdProvider(productId))
                      : ref.invalidate(publicProductByIdProvider(productId)),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (product) {
          if (product == null) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(backgroundColor: Colors.transparent),
              body: Center(
                child: Text(
                  'المنتج غير موجود',
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
              ),
            );
          }

          return _ProductDetailsView(
            product: product,
            isGuest: !isLoggedIn,
          );
        },
      ),
    );
  }
}

// =====================================================
// عرض التفاصيل
// =====================================================
class _ProductDetailsView extends ConsumerStatefulWidget {
  final ProductModel product;
  final bool isGuest;

  const _ProductDetailsView({
    required this.product,
    required this.isGuest,
  });

  @override
  ConsumerState<_ProductDetailsView> createState() =>
      _ProductDetailsViewState();
}

class _ProductDetailsViewState extends ConsumerState<_ProductDetailsView> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;

  ProductModel get product => widget.product;
  bool get isGuest => widget.isGuest;
  bool get isLoggedIn => !isGuest;

  /// كل الصور (main + gallery) — بدون الفيديو
  List<String> get _allImages {
    final images = <String>[];
    if (product.mainImageUrl != null && product.mainImageUrl!.isNotEmpty) {
      images.add(product.mainImageUrl!);
    }
    images.addAll(product.galleryImages.where((url) => url.isNotEmpty));
    return images;
  }

  /// الفيديو منفصل
  bool get _hasVideo =>
      product.videoUrl != null && product.videoUrl!.isNotEmpty;

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // =====================================================
          // AppBar
          // =====================================================
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            expandedHeight: 0,
            leading: _circleIconButton(
              icon: Icons.arrow_back,
              onTap: () {
                if (isLoggedIn) {
                  context.go('/products');
                } else {
                  context.go('/shop');
                }
              },
            ),
            actions: [
              if (isLoggedIn) ...[
                _circleIconButton(
                  icon: Icons.edit,
                  onTap: () => context.go('/products/edit/${product.id}'),
                ),
                const SizedBox(width: 8),
                _circleIconButton(
                  icon: Icons.delete_outline,
                  onTap: () => _confirmDelete(context),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),

          // =====================================================
          // معرض الصور (بدون الفيديو)
          // =====================================================
          SliverToBoxAdapter(
            child: _buildImageGallery(context, isDark),
          ),

          // =====================================================
          // Thumbnails (دايماً تحت الصورة)
          // =====================================================
          if (_allImages.length > 1)
            SliverToBoxAdapter(
              child: _buildImageThumbnails(context, isDark),
            ),

          // =====================================================
          // قسم الفيديو (منفصل)
          // =====================================================
          if (_hasVideo)
            SliverToBoxAdapter(
              child: _buildVideoSection(context, isDark),
            ),

          // =====================================================
          // محتوى المنتج
          // =====================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(context),
                  const SizedBox(height: 20),

                  // ⭐ كارت السعر — للمسجلين فقط
                  if (isLoggedIn) ...[
                    _buildPriceCard(context),
                    const SizedBox(height: 24),
                  ],

                  // البيانات الأساسية
                  _buildSection(
                    context,
                    icon: Icons.info_outline,
                    title: 'البيانات الأساسية',
                    isDark: isDark,
                    children: [
                      ProductInfoRow(
                        icon: Icons.category_outlined,
                        label: 'التصنيف',
                        value: product.categoryName,
                      ),
                      ProductInfoRow(
                        icon: Icons.straighten,
                        label: 'الوحدة',
                        value: product.unit,
                      ),
                      // ⭐ حد الطلب — للمسجلين فقط
                      if (isLoggedIn)
                        ProductInfoRow(
                          icon: Icons.warning_amber,
                          label: 'حد الطلب',
                          value: product.reorderLevel.toString(),
                        ),
                    ],
                  ),

                  // الوصف
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      icon: Icons.description_outlined,
                      title: 'الوصف',
                      isDark: isDark,
                      children: [
                        Text(
                          product.description!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // مواصفات الإضاءة
                  if (_hasLightingSpecs()) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      icon: Icons.lightbulb_outline,
                      title: 'مواصفات الإضاءة',
                      isDark: isDark,
                      children: [
                        _specRow(context, 'الجهد', product.voltage),
                        _specRow(context, 'القدرة', product.powerWatts),
                        _specRow(context, 'شدة الإضاءة', product.lumens),
                        _specRow(context, 'درجة الحرارة', product.colorTemp),
                        _specRow(context, 'زاوية الإضاءة', product.beamAngle),
                      ],
                    ),
                  ],

                  // مواصفات الشاشة
                  if (_hasScreenSpecs()) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      icon: Icons.tv_outlined,
                      title: 'مواصفات الشاشة',
                      isDark: isDark,
                      children: [
                        _specRow(context, 'Pixel Pitch', product.pixelPitch),
                        _specRow(context, 'السطوع', product.brightness),
                        _specRow(context, 'معدل التحديث', product.refreshRate),
                        _specRow(context, 'زاوية الرؤية', product.viewingAngle),
                      ],
                    ),
                  ],

                  // ملاحظات
                  if (product.notes != null && product.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      icon: Icons.note_outlined,
                      title: 'ملاحظات',
                      isDark: isDark,
                      children: [
                        Text(
                          product.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // معرض الصور
  // =====================================================
  Widget _buildImageGallery(BuildContext context, bool isDark) {
    if (_allImages.isEmpty) {
      return Container(
        height: 400,
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppTheme.lightBg,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 100,
            color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imageController,
            itemCount: _allImages.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageZoom(context, index),
                child: Container(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white,
                  child: CachedNetworkImage(
                    imageUrl: _allImages[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 80,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // مؤشر الصفحات
          if (_allImages.length > 1)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentImageIndex + 1} / ${_allImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================
  // Thumbnails (تحت الصورة على طول)
  // =====================================================
  Widget _buildImageThumbnails(BuildContext context, bool isDark) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _allImages.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentImageIndex;

          return GestureDetector(
            onTap: () {
              setState(() => _currentImageIndex = index);
              _imageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 70,
              height: 70,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.dividerColor),
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _allImages[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppTheme.lightBg,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.lightBg,
                    child: const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // قسم الفيديو (منفصل)
  // =====================================================
  Widget _buildVideoSection(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'فيديو المنتج',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // الفيديو
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _VideoPlayerWidget(videoUrl: product.videoUrl!),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // عنوان المنتج
  // =====================================================
  Widget _buildTitleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    product.sku,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // ⭐ حالة المنتج — للمسجلين فقط
            if (isLoggedIn)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: product.isActive
                      ? AppTheme.successColor.withValues(alpha: 0.15)
                      : AppTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      product.isActive ? Icons.check_circle : Icons.cancel,
                      size: 12,
                      color: product.isActive
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.isActive ? 'نشط' : 'متوقف',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: product.isActive
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // =====================================================
  // كارت السعر (للمسجلين فقط)
  // =====================================================
  Widget _buildPriceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor,
            AppTheme.successColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.attach_money,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'السعر',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(
                    Helpers.formatCurrency(product.price),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Section
  // =====================================================
  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _specRow(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasLightingSpecs() {
    return (product.voltage != null && product.voltage!.isNotEmpty) ||
        (product.powerWatts != null && product.powerWatts!.isNotEmpty) ||
        (product.lumens != null && product.lumens!.isNotEmpty) ||
        (product.colorTemp != null && product.colorTemp!.isNotEmpty) ||
        (product.beamAngle != null && product.beamAngle!.isNotEmpty);
  }

  bool _hasScreenSpecs() {
    return (product.pixelPitch != null && product.pixelPitch!.isNotEmpty) ||
        (product.brightness != null && product.brightness!.isNotEmpty) ||
        (product.refreshRate != null && product.refreshRate!.isNotEmpty) ||
        (product.viewingAngle != null && product.viewingAngle!.isNotEmpty);
  }

  // =====================================================
  // Helpers
  // =====================================================
  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  void _showImageZoom(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ImageZoomDialog(
        images: _allImages,
        initialIndex: index,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await Helpers.confirmDialog(
      context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف "${product.name}"؟',
      confirmText: 'حذف',
      confirmColor: AppTheme.errorColor,
    );

    if (!confirm) return;

    final success = await ref
        .read(productsControllerProvider.notifier)
        .deleteProduct(product.id);

    if (!context.mounted) return;

    if (success) {
      Helpers.showSuccess(context, 'تم حذف المنتج');
      context.go('/products');
    } else {
      Helpers.showError(context, 'فشل الحذف');
    }
  }
}

// =====================================================
// Video Player
// =====================================================
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Video error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, color: Colors.white54, size: 50),
              SizedBox(height: 8),
              Text(
                'فشل تحميل الفيديو',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          GestureDetector(
            onTap: _togglePlay,
            child: AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// Image Zoom Dialog
// =====================================================
class _ImageZoomDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageZoomDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImageZoomDialog> createState() => _ImageZoomDialogState();
}

class _ImageZoomDialogState extends State<_ImageZoomDialog> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

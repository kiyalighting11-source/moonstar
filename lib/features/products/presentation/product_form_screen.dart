// lib/features/products/presentation/product_form_screen.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../data/models/product_model.dart';
import '../providers/products_provider.dart';
import '../../../core/widgets/dashboard_app_bar.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  bool get isEdit => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();

  // =====================================================
  // Controllers
  // =====================================================
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchasePriceController = TextEditingController(); // ⭐ جديد
  final _reorderLevelController = TextEditingController(text: '10');
  final _notesController = TextEditingController();

  // مواصفات الإضاءة
  final _voltageController = TextEditingController();
  final _powerWattsController = TextEditingController();
  final _lumensController = TextEditingController();
  final _colorTempController = TextEditingController();
  final _beamAngleController = TextEditingController();

  // مواصفات الشاشة
  final _pixelPitchController = TextEditingController();
  final _brightnessController = TextEditingController();
  final _refreshRateController = TextEditingController();
  final _viewingAngleController = TextEditingController();

  // =====================================================
  // State
  // =====================================================
  // ⭐ التصنيفات - 3 مستويات
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubSubCategoryId;

  bool _isActive = true;
  bool _isLoading = false;

  // ===== الصور =====
  String? _mainImageUrl;
  XFile? _mainImageFile;

  List<String> _galleryUrls = [];
  List<XFile> _galleryFiles = [];

  // ===== الفيديو =====
  String? _videoUrl;
  XFile? _videoFile;

  // =====================================================
  // Lifecycle
  // =====================================================
  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadProduct();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _reorderLevelController.dispose();
    _notesController.dispose();
    _voltageController.dispose();
    _powerWattsController.dispose();
    _lumensController.dispose();
    _colorTempController.dispose();
    _beamAngleController.dispose();
    _pixelPitchController.dispose();
    _brightnessController.dispose();
    _refreshRateController.dispose();
    _viewingAngleController.dispose();
    super.dispose();
  }

  // =====================================================
  // Load Product (Edit mode)
  // =====================================================
  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product = await ref
          .read(productsRepositoryProvider)
          .getProductById(widget.productId!);

      if (product == null) {
        if (mounted) {
          Helpers.showError(context, 'المنتج غير موجود');
          context.go('/products');
        }
        return;
      }

      // البيانات الأساسية
      _nameController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.price.toString();
      _purchasePriceController.text = product.purchasePrice.toString();
      _reorderLevelController.text = product.reorderLevel.toString();
      _notesController.text = product.notes ?? '';

      // مواصفات الإضاءة
      _voltageController.text = product.voltage ?? '';
      _powerWattsController.text = product.powerWatts ?? '';
      _lumensController.text = product.lumens ?? '';
      _colorTempController.text = product.colorTemp ?? '';
      _beamAngleController.text = product.beamAngle ?? '';

      // مواصفات الشاشة
      _pixelPitchController.text = product.pixelPitch ?? '';
      _brightnessController.text = product.brightness ?? '';
      _refreshRateController.text = product.refreshRate ?? '';
      _viewingAngleController.text = product.viewingAngle ?? '';

      _isActive = product.isActive;
      _mainImageUrl = product.mainImageUrl;
      _galleryUrls = List.from(product.galleryImages);
      _videoUrl = product.videoUrl;

      // ⭐ التصنيف - نحدد المستوى بالظبط
      await _resolveCategoryHierarchy(product.categoryId);
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل تحميل المنتج: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ⭐ نحدد التصنيف على أي مستوى (رئيسي / فرعي / فرعي-فرعي)
  Future<void> _resolveCategoryHierarchy(String? categoryId) async {
    if (categoryId == null) return;

    try {
      final tree =
          await ref.read(productsRepositoryProvider).getAllCategories();

      for (final main in tree) {
        // المستوى 1
        if (main.id == categoryId) {
          _selectedMainCategoryId = main.id;
          return;
        }

        for (final sub in main.children) {
          // المستوى 2
          if (sub.id == categoryId) {
            _selectedMainCategoryId = main.id;
            _selectedSubCategoryId = sub.id;
            return;
          }

          for (final subSub in sub.children) {
            // المستوى 3
            if (subSub.id == categoryId) {
              _selectedMainCategoryId = main.id;
              _selectedSubCategoryId = sub.id;
              _selectedSubSubCategoryId = subSub.id;
              return;
            }
          }
        }
      }
    } catch (_) {
      // تجاهل - لو حصل خطأ، نخلي التصنيف فاضي
    }
  }

  // =====================================================
  // Image Pickers
  // =====================================================
  Future<void> _pickMainImage() async {
    final file = await _storage.pickImage();
    if (file == null) return;
    if (!mounted) return;
    setState(() => _mainImageFile = file);
  }

  Future<void> _pickGalleryImages() async {
    final files = await _storage.pickMultipleImages(max: 5);
    if (files.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _galleryFiles.addAll(files);
      if (_galleryFiles.length > 5) {
        _galleryFiles = _galleryFiles.take(5).toList();
      }
    });
  }

  Future<void> _pickVideoFile() async {
    final file = await _storage.pickVideo();
    if (file == null) return;
    if (!mounted) return;
    setState(() => _videoFile = file);
  }

  void _removeMainImage() {
    setState(() {
      _mainImageFile = null;
      _mainImageUrl = null;
    });
  }

  void _removeGalleryImage(int index) {
    setState(() {
      if (index < _galleryFiles.length) {
        _galleryFiles.removeAt(index);
      } else {
        final urlIndex = index - _galleryFiles.length;
        if (urlIndex < _galleryUrls.length) {
          _galleryUrls.removeAt(urlIndex);
        }
      }
    });
  }

  void _removeVideo() {
    setState(() {
      _videoFile = null;
      _videoUrl = null;
    });
  }

  // =====================================================
  // Save
  // =====================================================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1) رفع الصورة الرئيسية
      String? mainImageUrl = _mainImageUrl;
      if (_mainImageFile != null) {
        if (!mounted) return;
        Helpers.showInfo(context, 'جاري رفع الصورة الرئيسية...');

        mainImageUrl = await _storage.uploadImage(
          file: _mainImageFile!,
          folder: 'products/main',
        );
        if (mainImageUrl == null) {
          throw Exception('فشل رفع الصورة الرئيسية');
        }
      }

      // 2) رفع صور المعرض
      final galleryUrls = List<String>.from(_galleryUrls);
      if (_galleryFiles.isNotEmpty) {
        if (!mounted) return;
        Helpers.showInfo(context, 'جاري رفع صور المعرض...');

        for (final file in _galleryFiles) {
          final url = await _storage.uploadImage(
            file: file,
            folder: 'products/gallery',
          );
          if (url != null) galleryUrls.add(url);
        }
      }

      // 3) رفع الفيديو
      String? videoUrl = _videoUrl;
      if (_videoFile != null) {
        if (!mounted) return;
        Helpers.showInfo(context, 'جاري رفع الفيديو...');

        videoUrl = await _storage.uploadVideo(
          file: _videoFile!,
          folder: 'products/videos',
        );
        if (videoUrl == null) {
          throw Exception('فشل رفع الفيديو');
        }
      }

      // 4) ⭐ نحدد التصنيف النهائي (الأعمق اللي اتحدد)
      final finalCategoryId = _selectedSubSubCategoryId ??
          _selectedSubCategoryId ??
          _selectedMainCategoryId;

      // 5) بناء المنتج
      final product = ProductModel(
        id: widget.productId ?? '',
        sku: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categoryId: finalCategoryId,
        unit: 'قطعة',
        price: Helpers.parseDouble(_priceController.text),
        purchasePrice: Helpers.parseDouble(_purchasePriceController.text),
        reorderLevel: Helpers.parseInt(_reorderLevelController.text),
        mainImageUrl: mainImageUrl,
        galleryImages: galleryUrls,
        videoUrl: videoUrl,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        voltage: _voltageController.text.trim().isEmpty
            ? null
            : _voltageController.text.trim(),
        powerWatts: _powerWattsController.text.trim().isEmpty
            ? null
            : _powerWattsController.text.trim(),
        lumens: _lumensController.text.trim().isEmpty
            ? null
            : _lumensController.text.trim(),
        colorTemp: _colorTempController.text.trim().isEmpty
            ? null
            : _colorTempController.text.trim(),
        beamAngle: _beamAngleController.text.trim().isEmpty
            ? null
            : _beamAngleController.text.trim(),
        pixelPitch: _pixelPitchController.text.trim().isEmpty
            ? null
            : _pixelPitchController.text.trim(),
        brightness: _brightnessController.text.trim().isEmpty
            ? null
            : _brightnessController.text.trim(),
        refreshRate: _refreshRateController.text.trim().isEmpty
            ? null
            : _refreshRateController.text.trim(),
        viewingAngle: _viewingAngleController.text.trim().isEmpty
            ? null
            : _viewingAngleController.text.trim(),
        isActive: _isActive,
      );

      // 6) الحفظ
      final controller = ref.read(productsControllerProvider.notifier);
      final success = widget.isEdit
          ? await controller.updateProduct(product)
          : await controller.createProduct(product);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Helpers.showSuccess(
          context,
          widget.isEdit ? 'تم تحديث المنتج' : 'تم إضافة المنتج',
        );
        context.go('/products');
      } else {
        final error = ref.read(productsControllerProvider).error;
        Helpers.showError(context, 'فشل الحفظ: $error');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Helpers.showError(context, 'خطأ: $e');
    }
  }

  // =====================================================
  // Build
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: widget.isEdit ? 'تعديل منتج' : 'منتج جديد',
      ),
      body: _isLoading && widget.isEdit
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== الصور والفيديو =====
                  _sectionTitle(context, 'الصور والفيديو'),
                  _buildMediaSection(context),
                  const SizedBox(height: 24),

                  // ===== البيانات الأساسية =====
                  _sectionTitle(context, 'البيانات الأساسية'),
                  _buildTextField(
                    controller: _nameController,
                    label: 'اسم المنتج *',
                    icon: Icons.inventory_2_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'الوصف',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _priceController,
                    label: 'سعر البيع *',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'سعر البيع مطلوب';
                      if (Helpers.parseDouble(v) <= 0) {
                        return 'السعر لازم يكون أكبر من صفر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _purchasePriceController,
                    label: 'سعر الشراء',
                    icon: Icons.shopping_cart_outlined,
                    keyboardType: TextInputType.number,
                    helperText: 'لحساب الأرباح',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _reorderLevelController,
                    label: 'حد إعادة الطلب',
                    icon: Icons.warning_amber,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 24),

                  // ===== ⭐ التصنيف (3 مستويات) =====
                  _sectionTitle(context, 'التصنيف'),
                  _buildMainCategoryDropdown(),
                  const SizedBox(height: 12),
                  if (_selectedMainCategoryId != null)
                    _buildSubCategoryDropdown(),
                  if (_selectedSubCategoryId != null) ...[
                    const SizedBox(height: 12),
                    _buildSubSubCategoryDropdown(),
                  ],

                  const SizedBox(height: 24),

                  // ===== مواصفات الإضاءة =====
                  _sectionTitle(context, 'مواصفات الإضاءة (اختياري)'),
                  _buildTextField(
                    controller: _voltageController,
                    label: 'الجهد (فولت)',
                    icon: Icons.electric_bolt,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _powerWattsController,
                    label: 'القدرة (وات)',
                    icon: Icons.power,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _lumensController,
                    label: 'شدة الإضاءة (لومن)',
                    icon: Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _colorTempController,
                    label: 'درجة الحرارة اللونية (كلفن)',
                    icon: Icons.thermostat,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _beamAngleController,
                    label: 'زاوية الإضاءة',
                    icon: Icons.wb_sunny_outlined,
                  ),

                  const SizedBox(height: 24),

                  // ===== مواصفات الشاشة =====
                  _sectionTitle(context, 'مواصفات الشاشة (اختياري)'),
                  _buildTextField(
                    controller: _pixelPitchController,
                    label: 'Pixel Pitch',
                    icon: Icons.grid_on,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _brightnessController,
                    label: 'السطوع (nits)',
                    icon: Icons.brightness_high,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _refreshRateController,
                    label: 'معدل التحديث',
                    icon: Icons.refresh,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _viewingAngleController,
                    label: 'زاوية الرؤية',
                    icon: Icons.remove_red_eye_outlined,
                  ),

                  const SizedBox(height: 24),

                  // ===== الحالة =====
                  _sectionTitle(context, 'الحالة'),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text('منتج نشط'),
                    subtitle: const Text('المنتج يظهر في القائمة'),
                    activeThumbColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _notesController,
                    label: 'ملاحظات',
                    icon: Icons.note_outlined,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),

                  // ===== الأزرار =====
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        widget.isEdit ? 'تحديث' : 'حفظ',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.go('/products'),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // =====================================================
  // Media Section
  // =====================================================
  Widget _buildMediaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== الصورة الرئيسية =====
        Text(
          'الصورة الرئيسية',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        _buildMainImagePicker(context),
        const SizedBox(height: 16),

        // ===== صور المعرض =====
        Row(
          children: [
            Text(
              'صور المعرض',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const Spacer(),
            Text(
              '${_galleryFiles.length + _galleryUrls.length} / 5',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildGalleryGrid(context),
        const SizedBox(height: 16),

        // ===== الفيديو =====
        Text(
          'الفيديو',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        _buildVideoPicker(context),
      ],
    );
  }

  Widget _buildMainImagePicker(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: _pickMainImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: _mainImageFile != null
            ? Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              _mainImageFile!.path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_mainImageFile!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _circleButton(
                      icon: Icons.close,
                      color: AppTheme.errorColor,
                      onTap: _removeMainImage,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'جديد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _mainImageUrl != null
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _mainImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _circleButton(
                          icon: Icons.close,
                          color: AppTheme.errorColor,
                          onTap: _removeMainImage,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: AppTheme.primaryColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط لاختيار صورة',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final total = _galleryFiles.length + _galleryUrls.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // ===== الصور المحفوظة (URLs) =====
        ..._galleryUrls.asMap().entries.map((entry) {
          return _galleryImageTile(
            image: CachedNetworkImage(
              imageUrl: entry.value,
              fit: BoxFit.cover,
            ),
            onRemove: () => _removeGalleryImage(
              _galleryFiles.length + entry.key,
            ),
          );
        }),

        // ===== الصور الجديدة (Files) =====
        ..._galleryFiles.asMap().entries.map((entry) {
          return _galleryImageTile(
            image: kIsWeb
                ? Image.network(entry.value.path, fit: BoxFit.cover)
                : Image.file(File(entry.value.path), fit: BoxFit.cover),
            isNew: true,
            onRemove: () => _removeGalleryImage(entry.key),
          );
        }),

        // ===== زرار الإضافة =====
        if (total < 5)
          GestureDetector(
            onTap: _pickGalleryImages,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _galleryImageTile({
    required Widget image,
    required VoidCallback onRemove,
    bool isNew = false,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 90,
            height: 90,
            child: image,
          ),
        ),
        if (isNew)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'جديد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: _circleButton(
            icon: Icons.close,
            color: AppTheme.errorColor,
            size: 22,
            iconSize: 14,
            onTap: onRemove,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPicker(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: _pickVideoFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.infoColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _videoFile != null || _videoUrl != null
                    ? Icons.videocam
                    : Icons.videocam_outlined,
                color: AppTheme.infoColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _videoFile != null
                        ? 'فيديو جديد: ${_videoFile!.name}'
                        : _videoUrl != null
                            ? 'فيديو موجود'
                            : 'اضغط لاختيار فيديو',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MP4 / MOV — أقل من دقيقتين',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (_videoFile != null || _videoUrl != null)
              _circleButton(
                icon: Icons.close,
                color: AppTheme.errorColor,
                onTap: _removeVideo,
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 28,
    double iconSize = 18,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  // =====================================================
  // Helpers
  // =====================================================
  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        helperText: helperText,
      ),
    );
  }

  // =====================================================
  // ⭐ Category Dropdowns (3 levels)
  // =====================================================
  Widget _buildMainCategoryDropdown() {
    final categoriesAsync = ref.watch(mainCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (categories) => DropdownButtonFormField<String>(
        initialValue: _selectedMainCategoryId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'التصنيف الرئيسي',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        items: categories
            .map((cat) => DropdownMenuItem<String>(
                  value: cat.id,
                  child: Text(cat.name),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedMainCategoryId = value;
            _selectedSubCategoryId = null;
            _selectedSubSubCategoryId = null;
          });
        },
      ),
    );
  }

  Widget _buildSubCategoryDropdown() {
    final subAsync = ref.watch(subcategoriesProvider(_selectedMainCategoryId!));

    return subAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return DropdownButtonFormField<String>(
          initialValue: _selectedSubCategoryId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'التصنيف الفرعي',
            prefixIcon: Icon(Icons.subdirectory_arrow_right),
          ),
          items: categories
              .map((cat) => DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.name),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedSubCategoryId = value;
              _selectedSubSubCategoryId = null;
            });
          },
        );
      },
    );
  }

  /// ⭐ المستوى الثالث - نستخدم نفس الـ provider لأن العلاقة recursive
  Widget _buildSubSubCategoryDropdown() {
    final subAsync = ref.watch(subcategoriesProvider(_selectedSubCategoryId!));

    return subAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
      data: (categories) {
        // لو مفيش مستوى تالت، نخفي الـ dropdown
        if (categories.isEmpty) return const SizedBox.shrink();

        return DropdownButtonFormField<String>(
          initialValue: _selectedSubSubCategoryId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'التصنيف الفرعي (مستوى 3)',
            prefixIcon: Icon(Icons.subdirectory_arrow_right),
          ),
          items: categories
              .map((cat) => DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.name),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedSubSubCategoryId = value);
          },
        );
      },
    );
  }
}

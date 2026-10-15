// lib/features/settings/presentation/screens/company_info_screen.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

class CompanyInfoScreen extends ConsumerStatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  ConsumerState<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends ConsumerState<CompanyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String? _logoUrl;
  XFile? _logoFile;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();

      if (settings == null) {
        if (mounted) {
          Helpers.showError(context, 'الإعدادات غير موجودة');
        }
        return;
      }

      _nameController.text = settings.companyName;
      _phoneController.text = settings.companyPhone ?? '';
      _emailController.text = settings.companyEmail ?? '';
      _addressController.text = settings.companyAddress ?? '';
      _logoUrl = settings.companyLogoUrl;
    } catch (e) {
      if (mounted) Helpers.showError(context, 'فشل التحميل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final file = await _storage.pickImage();
    if (file == null) return;
    if (!mounted) return;
    setState(() => _logoFile = file);
  }

  void _removeLogo() {
    setState(() {
      _logoFile = null;
      _logoUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1) رفع الشعار لو فيه صورة جديدة
      String? logoUrl = _logoUrl;
      if (_logoFile != null) {
        if (!mounted) return;
        Helpers.showInfo(context, 'جاري رفع الشعار...');

        logoUrl = await _storage.uploadImage(
          file: _logoFile!,
          folder: 'company/logo',
        );
        if (logoUrl == null) {
          throw Exception('فشل رفع الشعار');
        }
      }

      // 2) نجيب الإعدادات الحالية
      final current = await ref.read(settingsRepositoryProvider).getSettings();
      if (current == null) throw Exception('الإعدادات غير موجودة');

      // 3) نحدّث
      final updated = current.copyWith(
        companyName: _nameController.text.trim(),
        companyLogoUrl: logoUrl,
        companyPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        companyEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        companyAddress: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      final success = await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(updated);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Helpers.showSuccess(context, 'تم الحفظ');
        setState(() {
          _logoFile = null;
          _logoUrl = logoUrl;
        });
      } else {
        final error = ref.read(settingsControllerProvider).error;
        Helpers.showError(context, 'فشل الحفظ: $error');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Helpers.showError(context, 'خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DashboardAppBar(
        title: 'معلومات الشركة',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== الشعار =====
                  Center(
                    child: GestureDetector(
                      onTap: _pickLogo,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.isDark(context)
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: AppTheme.cardShadow(context),
                            ),
                            child: ClipOval(
                              child: _buildLogoImage(context),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          if (_logoFile != null || _logoUrl != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _removeLogo,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'اضغط لتغيير الشعار',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== اسم الشركة =====
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الشركة *',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 12),

                  // ===== الهاتف =====
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== الإيميل =====
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!Helpers.isValidEmail(v)) {
                        return 'البريد غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ===== العنوان =====
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== الحفظ =====
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text(
                        'حفظ',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLogoImage(BuildContext context) {
    // صورة جديدة
    if (_logoFile != null) {
      return kIsWeb
          ? Image.network(_logoFile!.path, fit: BoxFit.cover)
          : Image.file(File(_logoFile!.path), fit: BoxFit.cover);
    }

    // صورة موجودة
    if (_logoUrl != null && _logoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _logoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, __, ___) => _logoPlaceholder(),
      );
    }

    return _logoPlaceholder();
  }

  Widget _logoPlaceholder() {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.business,
          size: 50,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

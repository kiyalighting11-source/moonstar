// lib/core/services/storage_service.dart

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  static const String bucketProducts = 'products';

  // =====================================================
  // اختيار من الجهاز
  // =====================================================
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      return await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
    } catch (e) {
      debugPrint('❌ pickImage error: $e');
      return null;
    }
  }

  Future<List<XFile>> pickMultipleImages({int max = 5}) async {
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      return files.take(max).toList();
    } catch (e) {
      debugPrint('❌ pickMultipleImages error: $e');
      return [];
    }
  }

  Future<XFile?> pickVideo() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
    } catch (e) {
      debugPrint('❌ pickVideo error: $e');
      return null;
    }
  }

  // =====================================================
  // رفع الملفات
  // =====================================================
  Future<String?> uploadImage({
    required XFile file,
    String folder = 'images',
  }) async {
    return _uploadFile(
      file: file,
      folder: folder,
      defaultExt: 'jpg',
    );
  }

  Future<String?> uploadVideo({
    required XFile file,
    String folder = 'videos',
  }) async {
    return _uploadFile(
      file: file,
      folder: folder,
      defaultExt: 'mp4',
    );
  }

  // =====================================================
  // الرفع الأساسي — مع كشف الأخطاء
  // =====================================================
  Future<String?> _uploadFile({
    required XFile file,
    required String folder,
    required String defaultExt,
  }) async {
    try {
      debugPrint('📤 بدء رفع الملف: ${file.name}');
      debugPrint('📁 المجلد: $folder');

      // 1) نتأكد إن المستخدم مسجل دخول
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ المستخدم مش مسجل دخول');
        throw Exception('يجب تسجيل الدخول أولاً');
      }
      debugPrint('👤 المستخدم: ${user.email}');

      // 2) نجهز الـ bytes
      final bytes = await file.readAsBytes();
      debugPrint('📦 حجم الملف: ${bytes.length} bytes');

      // 3) نحدد الامتداد
      final originalName = file.name;
      final ext = _getExtension(originalName) ?? defaultExt;
      debugPrint('📄 الامتداد: $ext');

      // 4) نعمل اسم فريد
      final fileName =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.$ext';
      debugPrint('🏷️ اسم الملف: $fileName');

      // 5) نرفع
      debugPrint('⬆️ جاري الرفع...');
      await _supabase.storage.from(bucketProducts).uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(ext),
              upsert: false,
            ),
          );
      debugPrint('✅ تم الرفع بنجاح');

      // 6) نرجع الـ public URL
      final url = _supabase.storage.from(bucketProducts).getPublicUrl(fileName);
      debugPrint('🔗 الرابط: $url');

      return url;
    } on StorageException catch (e) {
      // ⭐ أخطاء Supabase Storage المحددة
      debugPrint('❌ StorageException:');
      debugPrint('   - message: ${e.message}');
      debugPrint('   - statusCode: ${e.statusCode}');
      debugPrint('   - error: ${e.error}');
      rethrow;
    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Exception: $e');
      debugPrint('📍 Stack: $stackTrace');
      rethrow;
    }
  }

  // =====================================================
  // حذف ملف
  // =====================================================
  Future<bool> deleteFile(String publicUrl) async {
    try {
      final path = _extractPath(publicUrl);
      if (path == null) return false;

      await _supabase.storage.from(bucketProducts).remove([path]);
      return true;
    } catch (e) {
      debugPrint('❌ delete error: $e');
      return false;
    }
  }

  // =====================================================
  // Helpers
  // =====================================================
  String? _getExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return null;
    return parts.last.toLowerCase();
  }

  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }

  /// نستخرج الـ path من الـ public URL
  String? _extractPath(String publicUrl) {
    try {
      const marker = '/storage/v1/object/public/$bucketProducts/';
      final index = publicUrl.indexOf(marker);
      if (index == -1) return null;
      return publicUrl.substring(index + marker.length);
    } catch (_) {
      return null;
    }
  }
}

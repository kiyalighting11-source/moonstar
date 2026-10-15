// lib/core/utils/permission_service.dart

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// طلب صلاحية الموقع
  static Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// هل صلاحية الموقع ممنوحة؟
  static Future<bool> hasLocation() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  /// فتح إعدادات التطبيق
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// نتيجة شاملة للصلاحيات
  static Future<Map<String, bool>> checkAll() async {
    return {
      'location': await Permission.locationWhenInUse.isGranted,
    };
  }
}

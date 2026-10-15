// lib/core/utils/device_service.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// جلب Device ID فريد للجهاز
  /// - Android: androidId
  /// - iOS: identifierForVendor
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.id; // Android ID
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'unknown_ios';
      }
      return 'unknown_platform';
    } catch (_) {
      return 'unknown';
    }
  }

  /// معلومات الجهاز (للعرض)
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': info.model,
          'brand': info.brand,
          'version': info.version.release,
          'device_id': info.id,
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': info.utsname.machine,
          'name': info.name,
          'version': info.systemVersion,
          'device_id': info.identifierForVendor ?? 'unknown',
        };
      }
      return {
        'platform': 'Unknown',
        'device_id': 'unknown',
      };
    } catch (_) {
      return {
        'platform': 'Unknown',
        'device_id': 'unknown',
      };
    }
  }

  /// اسم الجهاز للعرض
  static Future<String> getDeviceName() async {
    final info = await getDeviceInfo();
    return '${info['brand'] ?? ''} ${info['model'] ?? ''}'.trim();
  }
}

// lib/core/utils/location_service.dart

import 'dart:io';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // =====================================================
  // التحقق من الصلاحيات
  // =====================================================

  /// هل خدمات الموقع مفعّلة؟
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// هل الصلاحيات ممنوحة؟
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// طلب صلاحية الموقع
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// يتأكد إن كل حاجة تمام (خدمة + صلاحية)
  /// Returns: null لو تمام، أو رسالة خطأ
  static Future<String?> ensureReady() async {
    // 1) خدمة الموقع مفعّلة؟
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'خدمة الموقع مقفولة. فعّلها من إعدادات الموبايل.';
    }

    // 2) الصلاحيات
    var permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return 'محتاجين صلاحية الموقع لتسجيل الحضور.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'صلاحية الموقع مرفوضة نهائياً. افتح الإعدادات وفعّلها.';
    }

    return null;
  }

  // =====================================================
  // إعدادات الموقع (حسب المنصة)
  // =====================================================

  static LocationSettings _buildSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.other,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
      );
    }
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: 0,
    );
  }

  // =====================================================
  // جلب الموقع الحالي
  // =====================================================

  /// جلب الموقع الحالي بدقة عالية
  static Future<Position?> getCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final error = await ensureReady();
      if (error != null) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: _buildSettings(
          accuracy: LocationAccuracy.high,
          timeout: timeout,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// جلب آخر موقع معروف (أسرع لكن أقل دقة)
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  // =====================================================
  // المسافة
  // =====================================================

  /// المسافة بين نقطتين بالمتر
  static double distanceBetween({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// هل النقطة دي جوه النطاق؟
  static bool isWithinRadius({
    required double currentLat,
    required double currentLng,
    required double targetLat,
    required double targetLng,
    required double radiusMeters,
  }) {
    final distance = distanceBetween(
      lat1: currentLat,
      lng1: currentLng,
      lat2: targetLat,
      lng2: targetLng,
    );
    return distance <= radiusMeters;
  }

  // =====================================================
  // فتح إعدادات الموقع
  // =====================================================

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

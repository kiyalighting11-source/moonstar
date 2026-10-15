// lib/core/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================
// ⭐ المفتاح في SharedPreferences
// =====================================================
const String _kThemeModeKey = 'theme_mode';

// =====================================================
// Provider للـ ThemeMode
// - Light / Dark / System
// - محفوظ في SharedPreferences
// =====================================================
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  // =====================================================
  // تحميل القيمة المحفوظة
  // =====================================================
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemeModeKey);
      if (saved != null) {
        state = _fromString(saved);
      }
    } catch (_) {
      // تجاهل الخطأ — يفضل ThemeMode.system
    }
  }

  // =====================================================
  // تعيين ThemeMode معين
  // =====================================================
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, _toString(mode));
    } catch (_) {
      // تجاهل الخطأ
    }
  }

  // =====================================================
  // ⭐ تبديل سريع بين Light و Dark
  // - لو Dark → Light
  // - غير كده → Dark
  // =====================================================
  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(next);
  }

  // =====================================================
  // Helpers
  // =====================================================
  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

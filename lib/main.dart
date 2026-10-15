// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/animated_gradient_background.dart';
import 'core/theme/app_theme.dart';

// ⭐ بنكتب الخطوات على الشاشة عشان نعرف وقف فين
void _log(String msg) {
  debugPrint('🎬 [MOONSTAR] $msg');
  // بنطبع كمان في stderr عشان يظهر في logcat
  // ignore: avoid_print
  print('🎬 [MOONSTAR] $msg');
}

Future<void> main() async {
  // ⭐ runZonedGuarded — أي crash هيتمسكه ويطبع
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _log('1. WidgetsFlutterBinding initialized');

      // =====================================================
      // 1) التاريخ
      // =====================================================
      try {
        _log('2. Initializing date formatting...');
        await initializeDateFormatting('ar', null);
        Intl.defaultLocale = 'ar';
        _log('2. ✅ Date formatting OK');
      } catch (e, st) {
        _log('2. ❌ Date formatting FAILED: $e');
        _log('$st');
      }

      // =====================================================
      // 2) Supabase
      // =====================================================
      try {
        _log('3. Initializing Supabase...');
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          publishableKey: SupabaseConfig.supabaseAnonKey,
        ).timeout(const Duration(seconds: 10));
        _log('3. ✅ Supabase OK');
      } catch (e, st) {
        _log('3. ❌ Supabase FAILED: $e');
        _log('$st');
        // بنكمل عادي
      }

      // =====================================================
      // 3) Error handlers
      // =====================================================
      FlutterError.onError = (details) {
        _log('❌ FlutterError: ${details.exceptionAsString()}');
        _log('${details.stack}');
      };

      // =====================================================
      // 4) تشغيل الأبلكيشن
      // =====================================================
      _log('4. Running app...');
      runApp(const ProviderScope(child: MoonstarApp()));
      _log('4. ✅ runApp called');
    },
    (error, stack) {
      // ⭐ أي async crash هنا
      _log('❌ UNCAUGHT ASYNC ERROR: $error');
      _log('$stack');
    },
  );
}

class MoonstarApp extends ConsumerWidget {
  const MoonstarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⭐ أول حاجة: تأكد إننا وصلنا للـ build ده
    debugPrint('🎬 [MOONSTAR] MoonstarApp.build() called');

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Moonstar ERP',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        // ⭐ ErrorWidget مخصص
        ErrorWidget.builder = (details) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'حصل خطأ غير متوقع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.exceptionAsString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        };

        return AnimatedGradientBackground(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

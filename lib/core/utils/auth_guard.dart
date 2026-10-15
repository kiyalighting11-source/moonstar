// lib/core/utils/auth_guard.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGuard {
  /// هل المستخدم مسجل دخول؟
  static bool get isLoggedIn {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null;
  }

  /// هل المستخدم زائر (غير مسجل)؟
  static bool get isGuest => !isLoggedIn;

  /// الحصول على المستخدم الحالي
  static User? get currentUser {
    return Supabase.instance.client.auth.currentUser;
  }

  /// الحصول على الـ session
  static Session? get currentSession {
    return Supabase.instance.client.auth.currentSession;
  }
}

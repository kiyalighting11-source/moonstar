// lib/features/auth/data/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Session? get currentSession => _supabase.auth.currentSession;

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final profileData = await _supabase
          .from(AppConstants.profileTable)
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) return null;

      final roleId = profileData['role_id'] as String?;
      if (roleId != null) {
        final roleData = await _supabase
            .from(AppConstants.rolesTable)
            .select('id, code, name_ar, name_en')
            .eq('id', roleId)
            .maybeSingle();

        profileData['roles'] = roleData;
      }

      return profileData;
    } catch (e) {
      return null;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }
}

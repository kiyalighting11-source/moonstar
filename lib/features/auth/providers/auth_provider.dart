// lib/features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

// =====================================================
// Repository Provider
// =====================================================
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// =====================================================
// حالة المصادقة (Stream)
// =====================================================
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// =====================================================
// المستخدم الحالي
// =====================================================
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => ref.read(authRepositoryProvider).currentUser,
  );
});

// =====================================================
// بروفايل المستخدم + الدور (FutureProvider)
// =====================================================
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  return await ref.read(authRepositoryProvider).getProfile();
});

// =====================================================
// كود الدور الحالي (Provider)
// =====================================================
final currentRoleProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return null;

  final role = profile['roles'];
  if (role is Map) return role['code'] as String?;
  return null;
});

// =====================================================
// حالة تسجيل الدخول (Auth Controller)
// =====================================================
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncValue.data(null));

  final AuthRepository _repo;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

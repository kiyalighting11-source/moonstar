// lib/core/providers/settings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../models/settings_model.dart';

// =====================================================
// Repository Provider
// =====================================================
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// =====================================================
// الإعدادات الحالية
// =====================================================
final settingsProvider = FutureProvider<SettingsModel?>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getSettings();
});

// =====================================================
// Controller
// =====================================================
class SettingsController extends StateNotifier<AsyncValue<void>> {
  SettingsController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final SettingsRepository _repo;
  final Ref _ref;

  Future<bool> updateSettings(SettingsModel settings) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateSettings(settings);
      state = const AsyncValue.data(null);
      _ref.invalidate(settingsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateCompanyLocation({
    required double lat,
    required double lng,
    int? radius,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCompanyLocation(lat: lat, lng: lng, radius: radius);
      state = const AsyncValue.data(null);
      _ref.invalidate(settingsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) {
  return SettingsController(ref.read(settingsRepositoryProvider), ref);
});

// lib/core/data/settings_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/settings_model.dart';

class SettingsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// نجيب الإعدادات (صف واحد بس)
  Future<SettingsModel?> getSettings() async {
    final data =
        await _supabase.from('settings').select('*').limit(1).maybeSingle();

    if (data == null) return null;
    return SettingsModel.fromJson(data);
  }

  /// تحديث الإعدادات
  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    final userId = _supabase.auth.currentUser?.id;

    final data = await _supabase
        .from('settings')
        .update({
          ...settings.toJson(),
          'updated_by': userId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', settings.id)
        .select('*')
        .single();

    return SettingsModel.fromJson(data);
  }

  /// حفظ إحداثيات الشركة (سريع)
  Future<void> updateCompanyLocation({
    required double lat,
    required double lng,
    int? radius,
  }) async {
    await _supabase.from('settings').update({
      'company_lat': lat,
      'company_lng': lng,
      if (radius != null) 'attendance_radius_meters': radius,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', (await getSettings())!.id);
  }
}

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prescription_model.dart';

class PrescriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cacheKeyPrefix = 'cached_prescriptions_';

  /// Watches prescriptions for a user. Emits cached data first, then updates from network.
  Stream<List<Prescription>> watchUserPrescriptions(String userId) async* {
    // 1. Immediately yield cached data
    final cached = await _loadFromCache(userId);
    if (cached.isNotEmpty) yield cached;

    // 2. Subscribe to network stream
    try {
      yield* _supabase
          .from('prescriptions')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .asyncMap((data) async {
            final prescriptions = data.map((json) => Prescription.fromJson(json)).toList();
            // Save successful network response to cache
            await _saveToCache(userId, data);
            return prescriptions;
          });
    } catch (e) {
      // If subscription fails, the stream will stay with the last yielded value (cache)
    }
  }

  /// Internal helper to save prescription JSON to local storage
  Future<void> _saveToCache(String userId, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_cacheKeyPrefix}$userId', jsonEncode(data));
    } catch (_) {}
  }

  /// Internal helper to load and parse cached prescriptions
  Future<List<Prescription>> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('${_cacheKeyPrefix}$userId');
      if (cachedStr != null) {
        final List decoded = jsonDecode(cachedStr);
        return decoded.map((json) => Prescription.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getOnlineDoctors() async {
    try {
      final response = await _supabase
          .from('telemed_doctors')
          .select()
          .eq('is_online', true)
          .order('current_wait_minutes');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}

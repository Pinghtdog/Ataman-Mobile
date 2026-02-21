import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prescription_model.dart';

class PrescriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cacheKeyPrefix = 'cached_prescriptions_';

  Stream<List<Prescription>> watchUserPrescriptions(String userId) async* {
    final cached = await _loadFromCache(userId);
    if (cached.isNotEmpty) yield cached;

    final networkStream = _supabase
        .from('prescriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final prescriptions = data.map((json) => Prescription.fromJson(json)).toList();
          await _saveToCache(userId, data);
          return prescriptions;
        })
        .handleError((error) {
          debugPrint('Prescription Stream Network Error (Suppressed): $error');
        });

    yield* networkStream;
  }

  Future<void> _saveToCache(String userId, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_cacheKeyPrefix}$userId', jsonEncode(data));
    } catch (_) {}
  }

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

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../models/ambulance_model.dart';
import '../models/emergency_request_model.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;

class EmergencyRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService? _geminiService;

  EmergencyRepository({GeminiService? geminiService}) : _geminiService = geminiService;

  Future<EmergencyRequest> createEmergencyRequest(EmergencyRequest request) async {
    try {
      return await createEmergencyRequestFromMap(request.toJson());
    } catch (e) {
      throw Exception('Failed to create emergency request: $e');
    }
  }

  /// Create from raw map - used by sync service
  Future<EmergencyRequest> createEmergencyRequestFromMap(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('emergency_requests')
          .insert(data)
          .select()
          .single();

      return EmergencyRequest.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create emergency request (remote): $e');
    }
  }

  /// Finds and assigns the best ambulance using location-based logic with AI fallback
  Future<Map<String, dynamic>> assignBestAmbulance({
    required String requestId,
    required double userLat,
    required double userLong,
    String? emergencyType,
  }) async {
    try {
      // 1. Fetch available ambulances
      final response = await _supabase
          .from('ambulances')
          .select()
          .eq('is_available', true);

      final ambulances = (response as List).map((json) => Ambulance.fromJson(json)).toList();

      if (ambulances.isEmpty) {
        throw Exception('No ambulances available at the moment.');
      }

      // 2. Calculate the nearest ambulance using Haversine formula
      Ambulance? nearestAmbulance;
      double minDistance = double.infinity;

      for (var ambulance in ambulances) {
        final distance = _calculateDistance(userLat, userLong, ambulance.latitude, ambulance.longitude);
        if (distance < minDistance) {
          minDistance = distance;
          nearestAmbulance = ambulance;
        }
      }

      if (nearestAmbulance == null) {
        throw Exception('Could not determine nearest ambulance.');
      }

      final recommendedId = nearestAmbulance.id;
      final reasoning = 'Nearest available ambulance found at approximately ${minDistance.toStringAsFixed(2)} km away.';

      // 3. Update Database
      await _supabase
          .from('emergency_requests')
          .update({
            'ambulance_id': recommendedId,
            'status': 'dispatched',
            'ai_assignment_reason': reasoning
          })
          .eq('id', requestId);

      // 4. Mark Ambulance as Unavailable
      await _supabase
          .from('ambulances')
          .update({'is_available': false})
          .eq('id', recommendedId);

      return {
        'recommended_ambulance_id': recommendedId,
        'reasoning': reasoning,
        'distance_km': minDistance
      };
    } catch (e) {
      throw Exception('Failed to assign ambulance: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Attempt to find an existing request that matches the given parameters.
  /// This helps resolve duplicates created offline.
  Future<EmergencyRequest?> findMatchingRequest({required String? userId, required double latitude, required double longitude, int withinSeconds = 120}) async {
    try {
      if (userId == null) return null;
      final since = DateTime.now().subtract(Duration(seconds: withinSeconds)).toIso8601String();
      final response = await _supabase
          .from('emergency_requests')
          .select()
          .eq('user_id', userId)
          .gte('created_at', since)
          .limit(10);

      final list = (response as List).map((json) => EmergencyRequest.fromJson(json)).toList();
      // Find nearest by simple distance threshold (50 meters)
      for (final r in list) {
        final d = ((r.latitude - latitude) * (r.latitude - latitude) + (r.longitude - longitude) * (r.longitude - longitude));
        if (d < 0.0005) {
          return r;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to find matching request: $e');
    }
  }

  Future<void> cancelEmergencyRequest(String requestId) async {
    try {
      await _supabase
          .from('emergency_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to cancel emergency request: $e');
    }
  }

  Stream<EmergencyRequest?> watchEmergencyRequest(String requestId) {
    return _supabase
        .from('emergency_requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .map((data) => data.isNotEmpty ? EmergencyRequest.fromJson(data.first) : null);
  }

  Stream<Ambulance?> watchAmbulanceLocation(String ambulanceId) {
    return _supabase
        .from('ambulances')
        .stream(primaryKey: ['id'])
        .eq('id', ambulanceId)
        .map((data) => data.isNotEmpty ? Ambulance.fromJson(data.first) : null);
  }

  Future<List<EmergencyRequest>> getUserEmergencyHistory(String userId) async {
    try {
      final response = await _supabase
          .from('emergency_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => EmergencyRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch emergency history: $e');
    }
  }
}

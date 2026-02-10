import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../models/ambulance_model.dart';
import '../models/emergency_request_model.dart';
import 'dart:async';
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

  /// Finds and assigns the best ambulance using AI
  Future<Map<String, dynamic>> assignBestAmbulance({
    required String requestId,
    required double userLat,
    required double userLong,
    String? emergencyType,
  }) async {
    if (_geminiService == null) throw Exception('GeminiService not initialized');

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

      // 2. Prepare prompt for Gemini
      final ambulanceData = ambulances.map((a) =>
        'ID: ${a.id}, Plate: ${a.plateNumber}, Loc: ${a.latitude}, ${a.longitude}'
      ).join('\n');

      final prompt = '''
Emergency Request ID: $requestId
User Location: $userLat, $userLong
Type of Emergency: ${emergencyType ?? 'General Medical'}
Available Ambulances:
$ambulanceData
''';

      // 3. Get AI Recommendation
      final aiResult = await _geminiService!.getAmbulanceAssignment(prompt);
      final recommendedId = aiResult['recommended_ambulance_id'];

      // 4. Update Database
      await _supabase
          .from('emergency_requests')
          .update({
            'ambulance_id': recommendedId,
            'status': 'dispatched',
            'ai_assignment_reason': aiResult['reasoning']
          })
          .eq('id', requestId);

      // 5. Mark Ambulance as Unavailable
      await _supabase
          .from('ambulances')
          .update({'is_available': false})
          .eq('id', recommendedId);

      return aiResult;
    } catch (e) {
      throw Exception('Failed to assign ambulance: $e');
    }
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

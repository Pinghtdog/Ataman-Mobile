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

  /// Maps EmergencyType to a priority score (Higher = More Urgent)
  int _getPriorityScore(EmergencyType type) {
    switch (type) {
      case EmergencyType.cardiac:
        return 100;
      case EmergencyType.sos:
        return 90;
      case EmergencyType.accident:
        return 80;
      case EmergencyType.maternal:
        return 70;
      case EmergencyType.ambulance:
        return 50;
      case EmergencyType.other:
      default:
        return 10;
    }
  }

  Future<EmergencyRequest> createEmergencyRequest(EmergencyRequest request) async {
    try {
      return await createEmergencyRequestFromMap(request.toJson());
    } catch (e) {
      throw Exception('Failed to create emergency request: $e');
    }
  }

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

  /// Advanced Assignment: Handles Proximity, Priority, and Pre-emption (Re-routing)
  Future<Map<String, dynamic>> assignBestAmbulance({
    required String requestId,
    required double userLat,
    required double userLong,
    EmergencyType? emergencyType,
  }) async {
    try {
      final int currentPriority = _getPriorityScore(emergencyType ?? EmergencyType.other);

      // 1. Fetch ALL ambulances (available or already dispatched)
      final response = await _supabase.from('ambulances').select();
      final allAmbulances = (response as List).map((json) => Ambulance.fromJson(json)).toList();

      if (allAmbulances.isEmpty) {
        throw Exception('No ambulances registered in the system.');
      }

      // 2. Separate into Available and Busy
      final availableAmbulances = allAmbulances.where((a) => a.isAvailable).toList();

      Ambulance? selectedAmbulance;
      double minDistance = double.infinity;
      bool isPreemption = false;

      if (availableAmbulances.isNotEmpty) {
        // --- NORMAL LOGIC: Pick nearest available ---
        for (var ambulance in availableAmbulances) {
          final distance = _calculateDistance(userLat, userLong, ambulance.latitude, ambulance.longitude);
          if (distance < minDistance) {
            minDistance = distance;
            selectedAmbulance = ambulance;
          }
        }
      } else if (currentPriority >= 80) {
        // --- PRE-EMPTION LOGIC: Check for re-routing if current case is High Priority (80+) ---
        // Find ambulances currently handling LOW priority cases (priority < 50)
        final activeRequestsResponse = await _supabase
            .from('emergency_requests')
            .select('id, type, assigned_ambulance_id')
            .eq('status', 'dispatched');

        final busyAmbulancesMap = {
          for (var r in (activeRequestsResponse as List)) 
            r['assigned_ambulance_id'].toString(): r
        };

        for (var ambulance in allAmbulances) {
          final currentTask = busyAmbulancesMap[ambulance.id];
          if (currentTask != null) {
            final taskPriority = _getPriorityScore(EmergencyType.values.firstWhere(
              (e) => e.name == currentTask['type'], 
              orElse: () => EmergencyType.other
            ));

            // If current task is significantly less urgent
            if (taskPriority < 50) {
              final distance = _calculateDistance(userLat, userLong, ambulance.latitude, ambulance.longitude);
              if (distance < minDistance) {
                minDistance = distance;
                selectedAmbulance = ambulance;
                isPreemption = true;
              }
            }
          }
        }
      }

      if (selectedAmbulance == null) {
        throw Exception('All ambulances are busy with high-priority cases. Please wait for the next available unit.');
      }

      // 3. DATABASE UPDATES
      return await _supabase.rpc('handle_ambulance_assignment', params: {
        'p_request_id': requestId,
        'p_ambulance_id': selectedAmbulance.id,
        'p_is_preemption': isPreemption,
        'p_priority': currentPriority,
      }).then((_) => {
        'recommended_ambulance_id': selectedAmbulance!.id,
        'reasoning': isPreemption 
            ? 'High-priority re-routing: Ambulance diverted from a lower-urgency task.' 
            : 'Nearest available ambulance assigned.',
        'distance_km': minDistance,
        'is_preemption': isPreemption
      });

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

  // ... rest of the existing methods (findMatchingRequest, cancel, watch, etc.)
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

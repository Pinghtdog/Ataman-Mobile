import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/emergency_request_model.dart';

class EmergencyRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<EmergencyRequest> createEmergencyRequest(EmergencyRequest request) async {
    try {
      final response = await _supabase
          .from('emergency_requests')
          .insert(request.toJson())
          .select()
          .single();
      
      return EmergencyRequest.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create emergency request: $e');
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

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prescription_model.dart';

/// [PrescriptionRepository] handles data operations related to medical prescriptions.
///
/// This repository facilitates:
/// 1. **Real-time Prescription Monitoring**: Provides a stream of prescriptions 
///    assigned to a specific user via Supabase Realtime.
/// 2. **Doctor Discovery**: Retrieves a list of medical professionals currently 
///    available for online consultation.
class PrescriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns a real-time [Stream] of [Prescription] objects for a given [userId].
  ///
  /// Listens to changes in the 'prescriptions' table and automatically 
  /// updates whenever a new prescription is added or an existing one is modified.
  Stream<List<Prescription>> watchUserPrescriptions(String userId) {
    return _supabase
        .from('prescriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) => data.map((json) => Prescription.fromJson(json)).toList());
  }

  /// Fetches a list of doctors who are currently flagged as online.
  /// 
  /// Results are ordered by `current_wait_minutes` to prioritize doctors 
  /// who can attend to patients more quickly.
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

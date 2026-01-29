import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prescription_model.dart';

class PrescriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Prescription>> watchUserPrescriptions(String userId) {
    return _supabase
        .from('prescriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) => data.map((json) => Prescription.fromJson(json)).toList());
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

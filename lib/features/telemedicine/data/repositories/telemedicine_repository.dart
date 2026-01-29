import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_model.dart';
import '../models/telemedicine_service_model.dart';
import '../../domain/repositories/i_telemedicine_repository.dart';

class TelemedicineRepository implements ITelemedicineRepository {
  final SupabaseClient _supabase;

  TelemedicineRepository(this._supabase);

  @override
  Stream<List<DoctorModel>> watchDoctors() {
    return _supabase
        .from('telemed_doctors')
        .stream(primaryKey: ['id'])
        .order('is_online', ascending: false)
        .map((data) => data.map((e) => DoctorModel.fromMap(e)).toList());
  }

  @override
  Future<List<TelemedicineService>> getServicesByCategory(String category) async {
    final response = await _supabase
        .from('telemedicine_services')
        .select()
        .eq('category', category)
        .eq('is_active', true);
    
    return (response as List).map((map) => TelemedicineService.fromMap(map)).toList();
  }

  @override
  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata}) async {
    // We now insert into telemed_sessions to match the Web Console
    final response = await _supabase.from('telemed_sessions').insert({
      'patient_id': patientId,
      'doctor_id': doctorId,
      'status': 'scheduled', // Web app looks for 'scheduled' or 'PENDING'
      'started_at': DateTime.now().toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    }).select().single();
    
    return response['id'] as String;
  }

  @override
  Future<void> updateCallStatus(String callId, String status) async {
    await _supabase.from('telemed_sessions').update({'status': status}).eq('id', callId);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCall(String callId) {
    return _supabase
        .from('telemed_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', callId);
  }

  Stream<List<Map<String, dynamic>>> watchCallSession(String patientId) {
    return _supabase
        .from('telemed_sessions')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('started_at', ascending: false)
        .limit(1);
  }
}

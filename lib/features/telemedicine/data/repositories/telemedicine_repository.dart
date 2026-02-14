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
  Future<List<Map<String, dynamic>>> getSymptomsByCategory(String category) async {
    final response = await _supabase
        .from('telemed_symptoms')
        .select('name')
        .eq('category', category)
        .eq('is_active', true)
        .order('display_order', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getDoctorAvailability(String doctorId) async {
    final response = await _supabase
        .from('doctor_availability')
        .select()
        .eq('doctor_id', doctorId)
        .eq('is_available', true);
    
    return List<Map<String, dynamic>>.from(response);
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
  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata, DateTime? scheduledTime}) async {
    final Map<String, dynamic> insertData = {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'status': scheduledTime == null ? 'active' : 'scheduled',
      'started_at': scheduledTime == null ? DateTime.now().toIso8601String() : null,
      'scheduled_time': scheduledTime?.toIso8601String(),
    };

    if (metadata != null) {
      insertData['metadata'] = metadata;
    }

    final response = await _supabase
        .from('telemed_sessions')
        .insert(insertData)
        .select()
        .single();
    
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

  @override
  Future<bool> checkBookingConflict(String patientId, String doctorId, DateTime startOfDay, DateTime endOfDay) async {
    final response = await _supabase
        .from('telemed_sessions')
        .select()
        .eq('patient_id', patientId)
        .eq('doctor_id', doctorId)
        .gte('scheduled_time', startOfDay.toIso8601String())
        .lte('scheduled_time', endOfDay.toIso8601String())
        .not('status', 'eq', 'cancelled');
    
    return (response as List).isEmpty;
  }

  @override
  Future<bool> hasAnyActiveSessions(String patientId) async {
    final response = await _supabase
        .from('telemed_sessions')
        .select()
        .eq('patient_id', patientId)
        .filter('status', 'in', '("scheduled","active")')
        .limit(1);

    return (response as List).isNotEmpty;
  }
}

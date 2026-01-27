import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_model.dart';
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
  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata}) async {
    final response = await _supabase.from('video_calls').insert({
      'patient_id': patientId,
      'doctor_id': doctorId,
      'status': 'calling',
      if (metadata != null) 'metadata': metadata,
    }).select().single();
    
    return response['id'] as String;
  }

  @override
  Future<void> updateCallStatus(String callId, String status) async {
    await _supabase.from('video_calls').update({'status': status}).eq('id', callId);
  }

  @override
  Future<void> addIceCandidate(String callId, Map<String, dynamic> candidate, String type) async {
    await _supabase.from('ice_candidates').insert({
      'call_id': callId,
      'candidate': candidate,
      'type': type,
    });
  }

  @override
  Future<void> updateCallOffer(String callId, Map<String, dynamic> offer) async {
    await _supabase.from('video_calls').update({
      'offer': offer
    }).eq('id', callId);
  }

  @override
  Future<void> updateCallAnswer(String callId, Map<String, dynamic> answer, String status) async {
    await _supabase.from('video_calls').update({
      'answer': answer,
      'status': status
    }).eq('id', callId);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCall(String callId) {
    return _supabase
        .from('video_calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchIceCandidates(String callId) {
    return _supabase
        .from('ice_candidates')
        .stream(primaryKey: ['id'])
        .eq('call_id', callId);
  }
}

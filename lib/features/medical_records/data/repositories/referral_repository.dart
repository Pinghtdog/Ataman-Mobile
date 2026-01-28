import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/base_repository.dart';
import '../models/referral_model.dart';
import '../../../triage/data/models/triage_model.dart';
import '../../../booking/data/models/booking_model.dart';

class ReferralRepository extends BaseRepository {
  final SupabaseClient _supabase;

  ReferralRepository(this._supabase);

  Future<String> createRapidReferral({
    required String userId,
    required TriageResult triageResult,
    required int destinationFacilityId,
    int? originFacilityId,
  }) async {
    final response = await _supabase.from('referrals').insert({
      'patient_id': userId,
      'origin_facility_id': originFacilityId,
      'destination_facility_id': destinationFacilityId,
      'chief_complaint': triageResult.rawSymptoms,
      'diagnosis_impression': triageResult.summaryForProvider,
      'status': 'PENDING',
      'ai_priority_score': triageResult.aiConfidence,
      'ai_recommended_destination_id': destinationFacilityId,
      'transport_type': triageResult.urgency == TriageUrgency.emergency ? 'AMBULANCE' : 'SELF',
    }).select().single();

    return response['reference_number'];
  }

  Future<void> createRapidReferralFromBooking({
    required String userId,
    required Booking booking,
  }) async {
    await _supabase.from('referrals').insert({
      'patient_id': userId,
      'destination_facility_id': booking.facilityId,
      'chief_complaint': booking.chiefComplaint ?? booking.triageResult,
      'diagnosis_impression': booking.triageResult,
      'status': 'PENDING',
      'transport_type': booking.triagePriority == 'emergency' ? 'AMBULANCE' : 'SELF',
      'service_stream': 'booking',
    });
  }

  Future<List<Referral>> getUserReferrals(String userId) async {
    final response = await _supabase
        .from('referrals')
        .select('*, origin:origin_facility_id(name), destination:destination_facility_id(name)')
        .eq('patient_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Referral.fromJson(json)).toList();
  }

  Stream<List<Referral>> watchMyReferrals(String userId) {
    return _supabase
        .from('referrals')
        .stream(primaryKey: ['id'])
        .eq('patient_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Referral.fromJson(json)).toList());
  }
}

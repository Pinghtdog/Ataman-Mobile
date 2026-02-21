import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/base_repository.dart';
import '../models/referral_model.dart';
import '../../../triage/data/models/triage_model.dart';
import '../../../booking/data/models/booking_model.dart';

/// [ReferralRepository] handles the persistence and real-time monitoring of medical referrals.
///
/// **Key Responsibilities:**
/// 1. **Rapid Referral Creation**: Automates the generation of referral records 
///    from AI triage results or emergency bookings.
/// 2. **Real-time Synchronization**: Provides a live stream of referrals for a 
///    specific user to track status changes (Pending -> Accepted).
/// 3. **Data Retrieval**: Fetches chronological history of a user's medical transfers.
///
/// **Note on Real-time Streams:**
/// Methods like [watchMyReferrals] utilize WebSockets. If a [RealtimeSubscribeStatus.timedOut] 
/// or "Failed host lookup" error occurs, it usually indicates a network or DNS issue 
/// on the client device.
class ReferralRepository extends BaseRepository {
  final SupabaseClient _supabase;

  ReferralRepository(this._supabase);

  /// Creates a new "Rapid Referral" record directly from an AI Triage result.
  /// 
  /// Automatically sets the priority score and transport type (Ambulance vs Self) 
  /// based on the [triageResult]'s urgency.
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

  /// Automatically generates a referral when an emergency booking is created.
  /// 
  /// Links the booking data (complaint, priority) to the referral system 
  /// to alert receiving facilities of an incoming patient.
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

  /// Fetches a one-time list of all referrals for a specific [userId].
  /// 
  /// Includes joined data for both origin and destination facility names.
  Future<List<Referral>> getUserReferrals(String userId) async {
    final response = await _supabase
        .from('referrals')
        .select('*, origin:origin_facility_id(name), destination:destination_facility_id(name)')
        .eq('patient_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Referral.fromJson(json)).toList();
  }

  /// Provides a real-time [Stream] of [Referral] records for a given [userId].
  /// 
  /// Ideal for use in UI [StreamBuilder]s to show immediate status updates 
  /// when a hospital accepts or modifies a referral.
  Stream<List<Referral>> watchMyReferrals(String userId) {
    return _supabase
        .from('referrals')
        .stream(primaryKey: ['id'])
        .eq('patient_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Referral.fromJson(json)).toList());
  }
}

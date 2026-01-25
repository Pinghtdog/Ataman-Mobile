import '../../../../core/data/repositories/base_repository.dart';
import '../models/referral_model.dart';

class ReferralRepository extends BaseRepository {
  Future<List<Referral>> getMyReferrals(String userId) async {
    return await getCached<List<Referral>>(
      'user_referrals_$userId',
      () async {
        final response = await safeCall(() => supabase
            .from('referrals')
            .select('*, origin_facility:facilities!origin_facility_id(name), destination_facility:facilities!destination_facility_id(name)')
            .eq('patient_id', userId)
            .order('created_at', ascending: false));
        
        return (response as List).map((json) => Referral.fromJson(json)).toList();
      },
      ttl: const Duration(minutes: 5),
    );
  }

  Stream<List<Referral>> watchMyReferrals(String userId) {
    return supabase
        .from('referrals')
        .stream(primaryKey: ['id'])
        .eq('patient_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Referral.fromJson(json)).toList());
  }
}

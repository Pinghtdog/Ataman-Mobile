import '../../../../core/data/repositories/base_repository.dart';
import '../models/vaccine_model.dart';

class VaccineRepository extends BaseRepository {
  
  /// Fetches all active vaccines from the master list with inventory/stock levels
  Future<List<Vaccine>> getAvailableVaccines() async {
    return await getCached<List<Vaccine>>(
      'available_vaccines_stock',
      () async {
        final response = await safeCall(() => supabase
            .from('vaccines')
            .select('''
              *,
              facility_vaccines (
                id,
                facility_id,
                stock_count,
                status,
                facilities (
                  name
                )
              )
            ''')
            .eq('is_active', true)
            .order('name', ascending: true));
        
        return (response as List).map((map) => Vaccine.fromMap(map)).toList();
      },
      ttl: const Duration(minutes: 5),
    );
  }

  /// Fetches a user's vaccination history/records
  Future<List<VaccineRecord>> getUserVaccineRecords(String userId) async {
    return await getCached<List<VaccineRecord>>(
      'user_vaccine_records_$userId',
      () async {
        final response = await safeCall(() => supabase
            .from('vaccine_records')
            .select('*, vaccines(name)')
            .eq('user_id', userId)
            .order('created_at', ascending: false));
        
        return (response as List).map((map) => VaccineRecord.fromMap(map)).toList();
      },
      ttl: const Duration(minutes: 5),
    );
  }

  /// Books a new vaccine appointment
  Future<void> bookVaccineAppointment({
    required String userId,
    required String vaccineId,
    required int doseNumber,
    required DateTime appointmentDate,
    required int facilityId,
  }) async {
    await safeCall(() => supabase.from('vaccine_records').insert({
      'user_id': userId,
      'vaccine_id': vaccineId,
      'dose_number': doseNumber,
      'next_dose_due': appointmentDate.toIso8601String(),
      'facility_id': facilityId,
      'status': 'PENDING',
    }));
    
    cache.invalidate('user_vaccine_records_$userId');
  }
}

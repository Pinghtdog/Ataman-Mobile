import '../models/facility_model.dart';
import 'base_repository.dart';

class FacilityRepository extends BaseRepository {
  
  Future<List<Facility>> getFacilities() async {
    return await getCached<List<Facility>>(
      'all_facilities',
      () async {
        final response = await safeCall(() => supabase
            .from('facilities')
            .select()
            .order('name'));
        
        return (response as List).map((json) => Facility.fromJson(json)).toList();
      },
      ttl: const Duration(minutes: 10),
    );
  }

  Future<List<Facility>> getFacilitiesByBarangay(String barangay) async {
    return await getCached<List<Facility>>(
      'facilities_brgy_$barangay',
      () async {
        final response = await safeCall(() => supabase
            .from('facilities')
            .select()
            .eq('barangay', barangay));
        
        return (response as List).map((json) => Facility.fromJson(json)).toList();
      }
    );
  }

  Stream<List<Facility>> watchFacilities() {
    return supabase
        .from('facilities')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Facility.fromJson(json)).toList());
  }

  Future<void> updateQueueCount(String facilityId, int count) async {
    await safeCall(() => supabase
        .from('facilities')
        .update({'current_queue_length': count})
        .eq('id', facilityId));
    
    // Invalidate relevant caches
    cache.invalidate('all_facilities');
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/facility_model.dart';

class FacilityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Facility>> getFacilities() async {
    try {
      final response = await _supabase
          .from('facilities')
          .select()
          .order('name');
      
      return (response as List).map((json) => Facility.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch facilities: $e');
    }
  }

  Future<List<Facility>> getFacilitiesByBarangay(String barangay) async {
    try {
      final response = await _supabase
          .from('facilities')
          .select()
          .eq('barangay', barangay);
      
      return (response as List).map((json) => Facility.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch facilities in $barangay: $e');
    }
  }

  Stream<List<Facility>> watchFacilities() {
    return _supabase
        .from('facilities')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Facility.fromJson(json)).toList());
  }

  Future<void> updateQueueCount(String facilityId, int count) async {
    try {
      await _supabase
          .from('facilities')
          .update({'current_queue_length': count})
          .eq('id', facilityId);
    } catch (e) {
      throw Exception('Failed to update queue count: $e');
    }
  }
}

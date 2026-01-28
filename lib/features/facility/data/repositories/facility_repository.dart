import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/facility_model.dart';
import '../models/facility_service_model.dart';

class FacilityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Facility>> getFacilities() async {
    final response = await _supabase
        .from('facilities')
        .select();
    
    return (response as List).map((json) => Facility.fromJson(json)).toList();
  }

  Stream<List<Facility>> watchFacilities() {
    return _supabase
        .from('facilities')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Facility.fromJson(json)).toList());
  }

  Future<List<FacilityService>> getFacilityServices(String facilityId) async {
    final response = await _supabase
        .from('facility_services')
        .select()
        .eq('facility_id', facilityId)
        .eq('is_available', true);
    
    return (response as List).map((json) => FacilityService.fromJson(json)).toList();
  }
}

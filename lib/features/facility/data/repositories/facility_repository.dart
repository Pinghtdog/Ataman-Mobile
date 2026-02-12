import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/facility_model.dart';
import '../models/facility_service_model.dart';

class FacilityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all facilities along with their real-time service statuses
  Future<List<Facility>> getFacilities() async {
    final response = await _supabase
        .from('facilities')
        .select('*, facility_services(*)');
    
    return (response as List).map((json) => Facility.fromJson(json)).toList();
  }

  /// Fetches a specific facility by its ID safely
  Future<Facility?> getFacilityById(String id) async {
    try {
      // Use maybeSingle() to return null instead of throwing an error if 0 rows found
      final response = await _supabase
          .from('facilities')
          .select('*, facility_services(*)')
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return null;
      return Facility.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Finds the best matching facility for a triage result
  Future<Facility?> findRecommendedFacility(String requiredCapability) async {
    final facilities = await getFacilities();

    for (var f in facilities) {
      final cap = requiredCapability.toUpperCase();
      if (f.capability.name.toUpperCase() == cap || f.shortCode == cap) {
        return f;
      }
    }

    if (requiredCapability.contains('HOSPITAL')) {
      return facilities.firstWhere((f) => f.type == FacilityType.hospital, orElse: () => facilities.first);
    }

    return facilities.isNotEmpty ? facilities.first : null;
  }

  /// Real-time stream of facilities and their service statuses
  Stream<List<Facility>> watchFacilities() {
    return _supabase
        .from('facilities')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final fullData = await _supabase
              .from('facilities')
              .select('*, facility_services(*)');
          return (fullData as List).map((json) => Facility.fromJson(json)).toList();
        });
  }

  Future<List<FacilityService>> getFacilityServices(String facilityId) async {
    final response = await _supabase
        .from('facility_services')
        .select()
        .eq('facility_id', facilityId);
    
    return (response as List).map((json) => FacilityService.fromJson(json)).toList();
  }
}

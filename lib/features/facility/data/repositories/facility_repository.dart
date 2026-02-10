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

  /// Finds the best matching facility for a triage result
  Future<Facility?> findRecommendedFacility(String requiredCapability) async {
    final facilities = await getFacilities();

    // Simple matching logic:
    // 1. Match capability (NCGH, BHS, etc.)
    // 2. Fallback to facility type if exact capability string varies
    for (var f in facilities) {
      final cap = requiredCapability.toUpperCase();
      if (f.capability.name.toUpperCase() == cap || f.shortCode == cap) {
        return f;
      }
    }

    // Broad fallback
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

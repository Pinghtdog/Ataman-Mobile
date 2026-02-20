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

  /// Finds the best matching facility for a triage result,
  /// respecting Dynamic Diversion Protocol and Fail-safe Heartbeats.
  Future<Facility?> findRecommendedFacility(String requiredCapability) async {
    final allFacilities = await getFacilities();
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    // 1. Filter for operational facilities with recent heartbeats (Dynamic Diversion Protocol)
    final viableFacilities = allFacilities.where((f) {
      final isStale = f.updatedAt.isBefore(fiveMinutesAgo); 
      return !f.isDiversionActive && 
             f.status == FacilityStatus.available && 
             !isStale;
    }).toList();

    // 2. Sort by best capability match first
    viableFacilities.sort((a, b) {
      final aIsMatch = a.capability.name.toUpperCase() == requiredCapability.toUpperCase();
      final bIsMatch = b.capability.name.toUpperCase() == requiredCapability.toUpperCase();
      if (aIsMatch && !bIsMatch) return -1;
      if (!aIsMatch && bIsMatch) return 1;
      return 0;
    });

    if (viableFacilities.isNotEmpty) {
      return viableFacilities.first;
    }

    // 3. FALLBACK STRATEGY: If no "ideal" facility is found
    // We provide a fallback based on the urgency of the situation
    
    // Fallback A: For Critical Emergencies (Trauma, Cardiac, etc.)
    // Route to the nearest Hospital Level 2 or 3, even if congested/stale (Emergency override)
    if (requiredCapability.contains('HOSPITAL') || requiredCapability.contains('TRAUMA')) {
      return allFacilities.firstWhere(
        (f) => (f.capability == FacilityCapability.hospitalLevel2 || 
                f.capability == FacilityCapability.hospitalLevel3),
        orElse: () => allFacilities.firstWhere((f) => f.type == FacilityType.hospital)
      );
    }

    // Fallback B: For Primary Care (Bite Center, Maternal, etc.)
    // Route to the nearest RHU (Rural Health Unit) if the BHS is down
    if (requiredCapability.contains('PRIMARY_CARE')) {
       return allFacilities.firstWhere(
         (f) => f.capability == FacilityCapability.ruralHealthUnit,
         orElse: () => allFacilities.first
       );
    }

    return null;
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

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/facility_model.dart';
import '../models/facility_service_model.dart';

class FacilityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cacheKey = 'cached_facilities';

  /// Fetches all facilities. Tries network first, falls back to cache if offline.
  Future<List<Facility>> getFacilities() async {
    try {
      final response = await _supabase
          .from('facilities')
          .select('*, facility_services(*)');
      
      final facilities = (response as List).map((json) => Facility.fromJson(json)).toList();
      
      // Save to cache asynchronously
      _saveToCache(response);
      
      return facilities;
    } catch (e) {
      // Return cached data if network fails
      return _loadFromCache();
    }
  }

  /// Internal helper to save raw JSON to local storage
  Future<void> _saveToCache(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (_) {}
  }

  /// Internal helper to load and parse cached data
  Future<List<Facility>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);
      if (cachedStr != null) {
        final List decoded = jsonDecode(cachedStr);
        return decoded.map((json) => Facility.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

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
      // Try to find in cache if specific ID fetch fails
      final cached = await _loadFromCache();
      try {
        return cached.firstWhere((f) => f.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  Future<Facility?> findRecommendedFacility(String requiredCapability) async {
    final allFacilities = await getFacilities();
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    final viableFacilities = allFacilities.where((f) {
      final isStale = f.updatedAt.isBefore(fiveMinutesAgo); 
      return !f.isDiversionActive && 
             f.status == FacilityStatus.available && 
             !isStale;
    }).toList();

    viableFacilities.sort((a, b) {
      final aIsMatch = a.capability.name.toUpperCase() == requiredCapability.toUpperCase();
      final bIsMatch = b.capability.name.toUpperCase() == requiredCapability.toUpperCase();
      if (aIsMatch && !bIsMatch) return -1;
      if (!aIsMatch && bIsMatch) return 1;
      return 0;
    });

    if (viableFacilities.isNotEmpty) return viableFacilities.first;

    if (requiredCapability.contains('HOSPITAL') || requiredCapability.contains('TRAUMA')) {
      try {
        return allFacilities.firstWhere(
          (f) => (f.capability == FacilityCapability.hospitalLevel2 || 
                  f.capability == FacilityCapability.hospitalLevel3)
        );
      } catch (_) {
        try { return allFacilities.firstWhere((f) => f.type == FacilityType.hospital); } catch (_) {}
      }
    }

    if (requiredCapability.contains('PRIMARY_CARE')) {
       try {
         return allFacilities.firstWhere((f) => f.capability == FacilityCapability.ruralHealthUnit);
       } catch (_) {
         if (allFacilities.isNotEmpty) return allFacilities.first;
       }
    }

    return null;
  }

  Stream<List<Facility>> watchFacilities() {
    return _supabase
        .from('facilities')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          try {
            final fullData = await _supabase
                .from('facilities')
                .select('*, facility_services(*)');
            _saveToCache(fullData);
            return (fullData as List).map((json) => Facility.fromJson(json)).toList();
          } catch (_) {
            return _loadFromCache();
          }
        });
  }

  Future<List<FacilityService>> getFacilityServices(String facilityId) async {
    try {
      final response = await _supabase
          .from('facility_services')
          .select()
          .eq('facility_id', facilityId);
      
      return (response as List).map((json) => FacilityService.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}

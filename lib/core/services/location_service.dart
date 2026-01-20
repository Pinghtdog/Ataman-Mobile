import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final _supabase = Supabase.instance.client;

  /// Checks permissions and returns current position
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Updates an ambulance's location in Supabase (Driver Side)
  static Future<void> updateAmbulanceLocation(String id, Position position) async {
    try {
      await _supabase.from('ambulances').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('Error updating ambulance location: $e');
    }
  }

  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  static String formatDistance(double km) {
    if (km < 1) return "${(km * 1000).toStringAsFixed(0)}m";
    return "${km.toStringAsFixed(1)}km";
  }
}

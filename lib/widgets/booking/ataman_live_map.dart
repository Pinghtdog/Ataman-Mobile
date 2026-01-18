import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AtamanLiveMap extends StatelessWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Function(GoogleMapController) onMapCreated;

  const AtamanLiveMap({
    super.key,
    required this.currentPosition,
    required this.markers,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    final CameraPosition initialCamera = CameraPosition(
      target: currentPosition != null
          ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
          : const LatLng(13.6218, 123.1844), // Naga City Center
      zoom: 14,
    );

    return GoogleMap(
      initialCameraPosition: initialCamera,
      onMapCreated: onMapCreated,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      markers: markers,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
    );
  }
}

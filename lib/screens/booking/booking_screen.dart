import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../constants/constants.dart';
import '../../data/models/facility_model.dart';
import '../../data/models/ambulance_model.dart';
import '../../widgets/ataman_header.dart';
import '../../widgets/booking/facility_card.dart';
import '../../services/location_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  
  StreamSubscription<List<Map<String, dynamic>>>? _ambulanceSubscription;
  
  List<Facility> _facilities = mockFacilities;
  List<Ambulance> _ambulances = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initLocationAndMarkers();
    _setupAmbulanceRealtime();
  }

  @override
  void dispose() {
    _ambulanceSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndMarkers() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _currentPosition = pos;
        _updateDistances(pos);
        _refreshMarkers();
      });
    }
  }

  void _setupAmbulanceRealtime() {
    _ambulanceSubscription = sb.Supabase.instance.client
        .from('ambulances')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              _ambulances = data.map((json) => Ambulance.fromJson(json)).toList();
              _refreshMarkers();
            });
          }
        });
  }

  void _updateDistances(Position pos) {
    setState(() {
      _facilities = _facilities.map((f) {
        if (f.latitude != null && f.longitude != null) {
          final double km = LocationService.calculateDistance(
            pos.latitude,
            pos.longitude,
            f.latitude!,
            f.longitude!,
          );
          return f.copyWith(distance: LocationService.formatDistance(km));
        }
        return f;
      }).toList();
    });
  }

  void _refreshMarkers() {
    final Set<Marker> newMarkers = {};

    for (var f in _facilities) {
      if (f.latitude != null && f.longitude != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('facility_${f.id}'),
            position: LatLng(f.latitude!, f.longitude!),
            infoWindow: InfoWindow(
              title: f.name, 
              snippet: f.isDiversionActive ? "DIVERSION ACTIVE" : f.status.name,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              f.isDiversionActive ? BitmapDescriptor.hueOrange :
              (f.status == FacilityStatus.available ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed),
            ),
          ),
        );
      }
    }

    for (var a in _ambulances) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('ambulance_${a.id}'),
          position: LatLng(a.latitude, a.longitude),
          infoWindow: InfoWindow(
            title: "Ambulance ${a.plateNumber}",
            snippet: a.isAvailable ? "Available" : "In Transit",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              AtamanHeader(
                height: 220,
                padding: const EdgeInsets.only(
                  top: 60,
                  left: AppSizes.p24,
                  right: AppSizes.p24,
                  bottom: AppSizes.p20
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Book Appointment",
                      style: AppTextStyles.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text(
                      "Find the nearest medical facility",
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: AppSizes.p20),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        cursorColor: Colors.white,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: "Search health centers, hospitals...",
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white, // Changed to white for visibility on teal
                            size: 22,
                          ),
                          contentPadding: const EdgeInsets.only(right: AppSizes.p16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isMapView ? _buildLiveMap() : _buildFacilityList(),
              ),
            ],
          ),

          // Floating Toggle
          Positioned(
            bottom: AppSizes.p24,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: () => setState(() => _isMapView = !_isMapView),
                backgroundColor: AppColors.textPrimary,
                icon: Icon(_isMapView ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
                    color: Colors.white),
                label: Text(
                  _isMapView ? "List View" : "Map View",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p12),
      itemCount: _facilities.length + 1,
      itemBuilder: (context, index) {
        if (index == _facilities.length) {
          return const SizedBox(height: 100); // More space for the floating button
        }
        return FacilityCard(
          facility: _facilities[index],
          onTap: () {
            // Handle navigation to booking detail
          },
        );
      },
    );
  }

  Widget _buildLiveMap() {
    final CameraPosition initialCamera = CameraPosition(
      target: _currentPosition != null 
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : const LatLng(13.6218, 123.1844), // Naga City Center
      zoom: 14,
    );

    return GoogleMap(
      initialCameraPosition: initialCamera,
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      markers: _markers,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
    );
  }
}

extension on FacilityStatus {
  String get name {
    switch (this) {
      case FacilityStatus.available: return "Available";
      case FacilityStatus.congested: return "Congested";
      case FacilityStatus.closed: return "Closed";
    }
  }
}

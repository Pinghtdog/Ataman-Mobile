import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/location_service.dart';
import '../../../emergency/data/models/ambulance_model.dart';
import '../../../facility/data/models/facility_model.dart';
import '../../../facility/logic/facility_cubit.dart';
import '../../../facility/logic/facility_state.dart';
import '../../../home/presentation/screens/ataman_base_screen.dart';
import '../../../triage/data/models/triage_model.dart';
import '../widgets/ataman_live_map.dart';
import '../widgets/facility_card.dart';
import '../widgets/facility_list_view.dart';
import 'booking_details_screen.dart';


class BookingScreen extends StatefulWidget {
  final TriageResult? triageResult;
  const BookingScreen({super.key, this.triageResult});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Facility? _selectedFacility;
  
  StreamSubscription<List<Map<String, dynamic>>>? _ambulanceSubscription;
  List<Ambulance> _ambulances = [];
  Set<Marker> _markers = {};

  final LatLng _nagaCityCenter = const LatLng(13.6193, 123.1598);

  @override
  void initState() {
    super.initState();
    _initLocation();
    context.read<FacilityCubit>().startWatchingFacilities();
    _setupAmbulanceRealtime();
    
    if (widget.triageResult != null) {
      _searchController.text = widget.triageResult!.specialty;
    }
  }

  @override
  void dispose() {
    _ambulanceSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _currentPosition = pos;
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
              _refreshMarkers(context.read<FacilityCubit>().state);
            });
          }
        });
  }

  void _refreshMarkers(FacilityState state) {
    if (state is! FacilityLoaded) return;
    
    final filteredFacilities = _filterFacilities(state.facilities);
    final Set<Marker> newMarkers = {};

    for (var f in filteredFacilities) {
      if (f.latitude != null && f.longitude != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('facility_${f.id}'),
            position: LatLng(f.latitude!, f.longitude!),
            onTap: () {
              setState(() {
                _selectedFacility = f;
              });
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(
              f.isDiversionActive ? BitmapDescriptor.hueOrange :
              (f.status == FacilityStatus.available ? BitmapDescriptor.hueGreen : 
               f.status == FacilityStatus.congested ? BitmapDescriptor.hueRed : 
               BitmapDescriptor.hueYellow),
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

  List<Facility> _filterFacilities(List<Facility> facilities) {
    if (widget.triageResult == null) return facilities;
    
    final String requiredCap = widget.triageResult!.requiredCapability.toUpperCase();

    return facilities.where((f) {
      // Logic: Show facilities that match or EXCEED the required capability for safety
      if (requiredCap == 'HOSPITAL_LEVEL_3') {
        return f.capability == FacilityCapability.hospitalLevel3;
      }
      if (requiredCap == 'HOSPITAL_LEVEL_2') {
        return f.capability == FacilityCapability.hospitalLevel3 || 
               f.capability == FacilityCapability.hospitalLevel2;
      }
      if (requiredCap == 'BARANGAY_HEALTH_STATION') {
        return f.type == FacilityType.bhc;
      }
      return true;
    }).toList();
  }

  void _reCenterCamera() {
    if (_mapController != null) {
      final target = _currentPosition != null 
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : _nagaCityCenter;
      
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15),
        ),
      );
    }
  }

  List<Facility> _processFacilities(List<Facility> facilities) {
    final filtered = _filterFacilities(facilities);
    if (_currentPosition == null) return filtered;
    
    return filtered.map((f) {
      if (f.latitude != null && f.longitude != null) {
        final double km = LocationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          f.latitude!,
          f.longitude!,
        );
        return f.copyWith(distance: LocationService.formatDistance(km));
      }
      return f;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AtamanBaseScreen.of(context)?.setNavbarVisibility(!_isMapView);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<FacilityCubit, FacilityState>(
        listener: (context, state) {
          if (state is FacilityLoaded) {
            _refreshMarkers(state);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  AtamanHeader(
                    height: widget.triageResult != null ? 260 : 220,
                    padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.triageResult != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  "AI Recommended: \${widget.triageResult!.requiredCapability.replaceAll('_', ' ')}",
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          "Book Appointment",
                          style: AppTextStyles.h2.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSizes.p8),
                        Text(
                          widget.triageResult != null 
                            ? "Showing facilities matching your triage results" 
                            : "Find the nearest medical facility",
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
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "Search health centers, hospitals...",
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: state is FacilityLoading
                      ? _buildShimmerList()
                      : state is FacilityError
                        ? Center(child: Text(state.message))
                        : state is FacilityLoaded
                          ? _isMapView 
                            ? AtamanLiveMap(
                                currentPosition: _currentPosition,
                                markers: _markers,
                                onMapCreated: (controller) => _mapController = controller,
                              ) 
                            : FacilityListView(
                                facilities: _processFacilities(state.facilities),
                                onFacilityTap: (facility) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingDetailsScreen(
                                        facility: facility,
                                        triageResult: widget.triageResult,
                                      ),
                                    ),
                                  );
                                },
                              )
                          : const SizedBox.shrink(),
                  ),
                ],
              ),

              if (_isMapView)
                Positioned(
                  top: 280,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _reCenterCamera,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),

              if (state is FacilityLoaded)
                Positioned(
                  bottom: _selectedFacility != null ? 320 : AppSizes.p24,
                  right: 24,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      setState(() {
                        _isMapView = !_isMapView;
                        _selectedFacility = null;
                      });
                    },
                    backgroundColor: AppColors.textPrimary,
                    icon: Icon(_isMapView ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
                        color: Colors.white),
                    label: Text(_isMapView ? "List View" : "Map View", style: const TextStyle(color: Colors.white)),
                  ),
                ),

              if (_isMapView && _selectedFacility != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    child: FacilityCard(
                      facility: _processFacilities([_selectedFacility!]).first,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailsScreen(
                              facility: _selectedFacility!,
                              triageResult: widget.triageResult,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.p20),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.p16),
        child: AtamanShimmer.rounded(height: 160),
      ),
    );
  }
}

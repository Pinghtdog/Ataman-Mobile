import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../constants/constants.dart';
import '../../data/models/facility_model.dart';
import '../../data/models/ambulance_model.dart';
import '../../logic/facility/facility_cubit.dart';
import '../../logic/facility/facility_state.dart';
import '../../widgets/ataman_header.dart';
import '../../widgets/booking/facility_list_view.dart';
import '../../widgets/booking/ataman_live_map.dart';
import '../../widgets/booking/facility_card.dart';
import '../../widgets/ataman_shimmer.dart';
import '../../services/location_service.dart';
import '../ataman_base_screen.dart';
import 'booking_details_screen.dart';

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
    
    final Set<Marker> newMarkers = {};

    for (var f in state.facilities) {
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
    if (_currentPosition == null) return facilities;
    
    return facilities.map((f) {
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
    // Control Navbar visibility
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
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                            cursorColor: Colors.white,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "Search health centers, hospitals...",
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.black45.withOpacity(0.6),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded, 
                                color: AppColors.primary,
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
                    child: state is FacilityLoading
                      ? _buildShimmerList()
                      : state is FacilityError
                        ? Center(child: Text(state.message))
                        : state is FacilityLoaded
                          ? _isMapView 
                            ? GestureDetector(
                                onTap: () => setState(() => _selectedFacility = null),
                                child: AtamanLiveMap(
                                  currentPosition: _currentPosition,
                                  markers: _markers,
                                  onMapCreated: (controller) => _mapController = controller,
                                ),
                              ) 
                            : FacilityListView(
                                facilities: _processFacilities(state.facilities),
                                onFacilityTap: (facility) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingDetailsScreen(facility: facility),
                                    ),
                                  );
                                },
                              )
                          : const SizedBox.shrink(),
                  ),
                ],
              ),

              // Floating Location Button
              if (_isMapView)
                Positioned(
                  top: 240,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _reCenterCamera,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),

              // Toggle Button
              if (state is FacilityLoaded)
                Positioned(
                  bottom: _selectedFacility != null ? 320 : AppSizes.p24,
                  left: 200,
                  right: 0,
                  child: Center(
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
                      label: Text(
                        _isMapView ? "List View" : "Map View",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),

              // Pull-up / Bottom Sheet Style Facility Card
              if (_isMapView && _selectedFacility != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 10) {
                        setState(() => _selectedFacility = null);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FacilityCard(
                            facility: _processFacilities([_selectedFacility!]).first,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingDetailsScreen(facility: _selectedFacility!),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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

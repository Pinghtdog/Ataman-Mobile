import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../auth/presentation/screens/patient_enrollment_screen.dart';
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
  String _searchQuery = "";
  
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
      _searchQuery = widget.triageResult!.specialty.toLowerCase();
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _ambulanceSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final state = context.read<FacilityCubit>().state;
    
    setState(() {
      _searchQuery = query;
      if (state is FacilityLoaded) {
        _refreshMarkers(state);
        
        // Auto-focus logic when searching in map view
        if (_isMapView && query.isNotEmpty) {
          final filtered = _filterFacilities(state.facilities);
          
          // If there's exactly one result or a perfect name match, zoom to it and open card
          Facility? bestMatch;
          if (filtered.length == 1) {
            bestMatch = filtered.first;
          } else {
            bestMatch = filtered.cast<Facility?>().firstWhere(
              (f) => f!.name.toLowerCase() == query,
              orElse: () => null,
            );
          }

          if (bestMatch != null && bestMatch.latitude != null && bestMatch.longitude != null) {
            _selectedFacility = bestMatch;
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(bestMatch.latitude!, bestMatch.longitude!),
                  zoom: 16,
                ),
              ),
            );
          }
        }
      }
    });
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
              
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(f.latitude!, f.longitude!),
                    zoom: 16,
                  ),
                ),
              );
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
    List<Facility> filtered = facilities;

    if (widget.triageResult != null) {
      final String requiredCap = widget.triageResult!.requiredCapability.toUpperCase();
      filtered = filtered.where((f) {
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

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((f) {
        return f.name.toLowerCase().contains(_searchQuery) ||
               f.address.toLowerCase().contains(_searchQuery) ||
               (f.barangay?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return filtered;
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

  void _onFacilitySelected(Facility facility) {
    final authState = context.read<AuthCubit>().state;
    
    if (authState is Authenticated) {
      if (authState.profile == null || !authState.profile!.isProfileComplete) {
        if (authState.profile != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientEnrollmentScreen(user: authState.profile!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile not found. Please try again.")),
          );
        }
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(
          facility: facility,
          triageResult: widget.triageResult,
        ),
      ),
    );
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
                                  "AI Recommended: ${widget.triageResult!.requiredCapability.replaceAll('_', ' ')}",
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
                            style: const TextStyle(color: Colors.black54),
                            cursorColor: Colors.white,
                            onSubmitted: (_) {
                              // Force selection of the first result if searching in map view
                              if (_isMapView && _searchQuery.isNotEmpty) {
                                final state = context.read<FacilityCubit>().state;
                                if (state is FacilityLoaded) {
                                  final filtered = _filterFacilities(state.facilities);
                                  if (filtered.isNotEmpty) {
                                    final match = filtered.first;
                                    setState(() {
                                      _selectedFacility = match;
                                    });
                                    _mapController?.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: LatLng(match.latitude!, match.longitude!),
                                          zoom: 16,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "Search health centers, hospitals...",
                              hintStyle: TextStyle(color: Colors.black45.withOpacity(0.6)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedFacility != null) {
                          setState(() => _selectedFacility = null);
                        }
                      },
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
                                  onFacilityTap: _onFacilitySelected,
                                )
                            : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),

              if (_isMapView)
                Positioned(
                  top: widget.triageResult != null ? 280 : 240,
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
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 10) {
                        setState(() => _selectedFacility = null);
                      }
                    },
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        child: FacilityCard(
                          facility: _processFacilities([_selectedFacility!]).first,
                          onTap: () => _onFacilitySelected(_selectedFacility!),
                        ),
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

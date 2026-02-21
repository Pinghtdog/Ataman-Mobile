import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/facility_repository.dart';
import 'facility_state.dart';

/// [FacilityCubit] manages the state and logic for medical facility discovery and real-time monitoring.
///
/// It coordinates with the [FacilityRepository] to provide both one-time fetches and
/// live stream updates of facility availability, statuses, and location data.
///
/// This cubit is essential for the booking and emergency features, ensuring that the 
/// user always sees the most accurate "Live" status of hospitals and health centers.
class FacilityCubit extends Cubit<FacilityState> {
  final FacilityRepository _facilityRepository;
  StreamSubscription? _facilitySubscription;

  FacilityCubit({required FacilityRepository facilityRepository})
      : _facilityRepository = facilityRepository,
        super(FacilityInitial());

  /// Performs a one-time fetch of all medical facilities.
  ///
  /// Emits [FacilityLoading] during the request and [FacilityLoaded] upon success.
  /// If the fetch fails, it emits [FacilityError] with the error details.
  Future<void> fetchFacilities() async {
    emit(FacilityLoading());
    try {
      final facilities = await _facilityRepository.getFacilities();
      emit(FacilityLoaded(facilities));
    } catch (e) {
      emit(FacilityError(e.toString()));
    }
  }

  /// Initializes a real-time subscription to facility data updates.
  ///
  /// This method uses Supabase Realtime (via the repository) to push updates to the UI
  /// whenever a facility's status (e.g., Diversion active, available beds) changes.
  /// Any existing subscription is cancelled before starting a new one.
  void startWatchingFacilities() {
    emit(FacilityLoading());
    _facilitySubscription?.cancel();
    _facilitySubscription = _facilityRepository.watchFacilities().listen(
      (facilities) {
        emit(FacilityLoaded(facilities));
      },
      onError: (error) {
        emit(FacilityError(error.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _facilitySubscription?.cancel();
    return super.close();
  }
}

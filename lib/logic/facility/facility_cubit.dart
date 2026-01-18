import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/facility_repository.dart';
import 'facility_state.dart';

class FacilityCubit extends Cubit<FacilityState> {
  final FacilityRepository _facilityRepository;
  StreamSubscription? _facilitySubscription;

  FacilityCubit({required FacilityRepository facilityRepository})
      : _facilityRepository = facilityRepository,
        super(FacilityInitial());

  Future<void> fetchFacilities() async {
    emit(FacilityLoading());
    try {
      final facilities = await _facilityRepository.getFacilities();
      emit(FacilityLoaded(facilities));
    } catch (e) {
      emit(FacilityError(e.toString()));
    }
  }

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

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ataman/core/services/local_storage_service.dart';
import 'package:ataman/injector.dart';
import '../data/models/emergency_request_model.dart';
import '../data/repositories/emergency_repository.dart';
import 'emergency_state.dart';

class EmergencyCubit extends Cubit<EmergencyState> {
  final EmergencyRepository _emergencyRepository;
  StreamSubscription? _requestSubscription;
  StreamSubscription? _ambulanceSubscription;

  EmergencyCubit({required EmergencyRepository emergencyRepository})
      : _emergencyRepository = emergencyRepository,
        super(EmergencyInitial());

  Future<void> requestEmergency(EmergencyRequest request) async {
    emit(EmergencyLoading());
    try {
      // 1. Create the request
      final newRequest = await _emergencyRepository.createEmergencyRequest(request);
      emit(EmergencyActive(newRequest));
      _startWatchingRequest(newRequest.id);

      // 2. Automatically trigger Intelligent AI Assignment
      try {
        await _emergencyRepository.assignBestAmbulance(
          requestId: newRequest.id,
          userLat: request.latitude,
          userLong: request.longitude,
          emergencyType: request.type.toString(),
        );
      } catch (aiError) {
        // Log AI error but don't fail the request. 
        // A dispatcher or manual process might still pick it up.
        print('AI Assignment failed: $aiError');
      }
      
    } catch (e) {
      // On failure (likely network), save to local queue for later sync
      try {
        await getIt<LocalStorageService>().savePendingEmergency(request.toJson());
        emit(EmergencyQueued(request.toJson()));
      } catch (e2) {
        emit(EmergencyError(e.toString()));
      }
    }
  }

  void _startWatchingRequest(String requestId) {
    _requestSubscription?.cancel();
    _requestSubscription = _emergencyRepository.watchEmergencyRequest(requestId).listen(
      (request) {
        if (request != null) {
          final currentState = state;
          if (currentState is EmergencyActive) {
             emit(currentState.copyWith(request: request));
          } else {
             emit(EmergencyActive(request));
          }

          if (request.status == EmergencyStatus.completed) {
            _ambulanceSubscription?.cancel();
            emit(EmergencySuccess());
          }

          // If an ambulance is assigned, start watching its location
          if (request.assignedAmbulanceId != null) {
             // If we aren't watching yet, or the ID changed
             _startWatchingAmbulance(request.assignedAmbulanceId!);
          }
        }
      },
      onError: (error) {
        emit(EmergencyError(error.toString()));
      },
    );
  }

  void _startWatchingAmbulance(String ambulanceId) {
    // Only restart if the ID is different or not yet watching
    // (Optimization to avoid flickering/re-subscribing on every DB update)
    _ambulanceSubscription?.cancel();
    _ambulanceSubscription = _emergencyRepository.watchAmbulanceLocation(ambulanceId).listen(
      (ambulance) {
        final currentState = state;
        if (currentState is EmergencyActive) {
          emit(currentState.copyWith(ambulance: ambulance));
        }
      },
      onError: (error) {
        // We don't want to break the whole flow if ambulance tracking fails
        print('Ambulance tracking error: $error');
      },
    );
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await _emergencyRepository.cancelEmergencyRequest(requestId);
      _requestSubscription?.cancel();
      _ambulanceSubscription?.cancel();
      emit(EmergencyInitial());
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _requestSubscription?.cancel();
    _ambulanceSubscription?.cancel();
    return super.close();
  }
}

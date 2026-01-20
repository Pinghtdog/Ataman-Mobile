import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/emergency_request_model.dart';
import '../data/repositories/emergency_repository.dart';
import 'emergency_state.dart';

class EmergencyCubit extends Cubit<EmergencyState> {
  final EmergencyRepository _emergencyRepository;
  StreamSubscription? _requestSubscription;

  EmergencyCubit({required EmergencyRepository emergencyRepository})
      : _emergencyRepository = emergencyRepository,
        super(EmergencyInitial());

  Future<void> requestEmergency(EmergencyRequest request) async {
    emit(EmergencyLoading());
    try {
      final newRequest = await _emergencyRepository.createEmergencyRequest(request);
      emit(EmergencyActive(newRequest));
      _startWatchingRequest(newRequest.id);
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }

  void _startWatchingRequest(String requestId) {
    _requestSubscription?.cancel();
    _requestSubscription = _emergencyRepository.watchEmergencyRequest(requestId).listen(
      (request) {
        if (request != null) {
          emit(EmergencyActive(request));
          if (request.status == EmergencyStatus.completed) {
            emit(EmergencySuccess());
          }
        }
      },
      onError: (error) {
        emit(EmergencyError(error.toString()));
      },
    );
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await _emergencyRepository.cancelEmergencyRequest(requestId);
      _requestSubscription?.cancel();
      emit(EmergencyInitial());
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _requestSubscription?.cancel();
    return super.close();
  }
}

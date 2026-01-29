import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/doctor_model.dart';
import '../data/models/telemedicine_service_model.dart';
import '../domain/repositories/i_telemedicine_repository.dart';

abstract class TelemedicineState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TelemedicineInitial extends TelemedicineState {}
class TelemedicineLoading extends TelemedicineState {}

class TelemedicineDoctorsLoaded extends TelemedicineState {
  final List<DoctorModel> doctors;
  TelemedicineDoctorsLoaded(this.doctors);
  @override
  List<Object?> get props => [doctors];
}

class TelemedicineDataLoaded extends TelemedicineState {
  final List<DoctorModel> doctors;
  final List<TelemedicineService> services;
  TelemedicineDataLoaded({required this.doctors, required this.services});
  @override
  List<Object?> get props => [doctors, services];
}

class TelemedicineError extends TelemedicineState {
  final String message;
  TelemedicineError(this.message);
  @override
  List<Object?> get props => [message];
}

class TelemedicineCubit extends Cubit<TelemedicineState> {
  final ITelemedicineRepository _repository;
  StreamSubscription? _doctorsSubscription;

  TelemedicineCubit(this._repository) : super(TelemedicineInitial());

  void startWatchingDoctors() {
    emit(TelemedicineLoading());
    _doctorsSubscription?.cancel();
    _doctorsSubscription = _repository.watchDoctors().listen(
      (doctors) {
        if (state is TelemedicineDataLoaded) {
          final currentServices = (state as TelemedicineDataLoaded).services;
          emit(TelemedicineDataLoaded(doctors: doctors, services: currentServices));
        } else {
          emit(TelemedicineDoctorsLoaded(doctors));
        }
      },
      onError: (error) {
        emit(TelemedicineError(error.toString()));
      },
    );
  }

  Future<void> loadServicesAndDoctors(String category) async {
    emit(TelemedicineLoading());
    try {
      final services = await _repository.getServicesByCategory(category);
      
      _doctorsSubscription?.cancel();
      _doctorsSubscription = _repository.watchDoctors().listen(
        (doctors) {
          emit(TelemedicineDataLoaded(doctors: doctors, services: services));
        },
        onError: (error) {
          emit(TelemedicineError(error.toString()));
        },
      );
    } catch (e) {
      emit(TelemedicineError(e.toString()));
    }
  }

  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata}) async {
    return await _repository.initiateCall(patientId, doctorId, metadata: metadata);
  }

  Future<void> updateCallStatus(String callId, String status) async {
    await _repository.updateCallStatus(callId, status);
  }

  @override
  Future<void> close() {
    _doctorsSubscription?.cancel();
    return super.close();
  }
}

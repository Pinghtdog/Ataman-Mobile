import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/doctor_model.dart';
import '../data/models/telemedicine_service_model.dart';
import '../domain/repositories/i_telemedicine_repository.dart';

part 'telemedicine_state.dart';

class TelemedicineCubit extends Cubit<TelemedicineState> {
  final ITelemedicineRepository _repository;
  StreamSubscription? _doctorsSubscription;

  TelemedicineCubit(this._repository) : super(TelemedicineInitial());

  void startWatchingDoctors() {
    emit(TelemedicineLoading());
    _doctorsSubscription?.cancel();
    _doctorsSubscription = _repository.watchDoctors().listen(
      (doctors) {
        final currentServices = state is TelemedicineLoaded 
            ? (state as TelemedicineLoaded).services 
            : <TelemedicineService>[];
        final currentSymptoms = state is TelemedicineLoaded
            ? (state as TelemedicineLoaded).symptoms
            : <String>[];
            
        emit(TelemedicineLoaded(
          doctors, 
          services: currentServices,
          symptoms: currentSymptoms,
        ));
      },
      onError: (error) {
        emit(TelemedicineError(error.toString()));
      },
    );
  }

  Future<List<Map<String, dynamic>>> getDoctorAvailability(String doctorId) async {
    try {
      return await _repository.getDoctorAvailability(doctorId);
    } catch (e) {
      print("Error fetching availability: $e");
      return [];
    }
  }

  Future<bool> checkBookingConflict(String patientId, String doctorId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      // This would normally be in the repository, but adding here for quick implementation
      // as requested to fix the double booking.
      return await _repository.checkBookingConflict(patientId, doctorId, startOfDay, endOfDay);
    } catch (e) {
      print("Error checking conflict: $e");
      return true; // Default to allowing if check fails, or false to be safe
    }
  }

  Future<List<Map<String, dynamic>>> getSymptomsByCategory(String category) async {
    try {
      return await _repository.getSymptomsByCategory(category);
    } catch (e) {
      print("Error fetching symptoms: $e");
      return [];
    }
  }

  Future<void> loadSymptoms(String category) async {
    try {
      final symptomsData = await _repository.getSymptomsByCategory(category);
      final symptomNames = symptomsData.map((s) => s['name'] as String).toList();
      
      if (state is TelemedicineLoaded) {
        final currentState = state as TelemedicineLoaded;
        emit(currentState.copyWith(symptoms: symptomNames));
      }
    } catch (e) {
      print("Error loading symptoms: $e");
    }
  }

  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata, DateTime? scheduledTime}) async {
    try {
      return await _repository.initiateCall(patientId, doctorId, metadata: metadata, scheduledTime: scheduledTime);
    } catch (e) {
      throw Exception('Failed to initiate consultation: $e');
    }
  }

  Future<void> updateCallStatus(String callId, String status) async {
    try {
      await _repository.updateCallStatus(callId, status);
    } catch (e) {
      emit(TelemedicineError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _doctorsSubscription?.cancel();
    return super.close();
  }
}

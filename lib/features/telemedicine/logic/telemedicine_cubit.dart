import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/notification_service.dart';
import '../../../injector.dart';
import '../data/models/doctor_model.dart';
import '../data/models/telemedicine_service_model.dart';
import '../domain/repositories/i_telemedicine_repository.dart';

part 'telemedicine_state.dart';

class TelemedicineCubit extends Cubit<TelemedicineState> {
  final ITelemedicineRepository _repository;
  StreamSubscription? _doctorsSubscription;
  StreamSubscription? _sessionsSubscription;
  final Map<String, Timer> _sessionReminders = {};

  TelemedicineCubit(this._repository) : super(TelemedicineInitial());

  void startWatchingDoctors() {
    emit(TelemedicineLoading());
    _doctorsSubscription?.cancel();
    _doctorsSubscription = _repository.watchDoctors().listen(
      (doctors) {
        if (state is TelemedicineLoaded) {
          final currentState = state as TelemedicineLoaded;
          emit(currentState.copyWith(doctors: doctors));
        } else {
          emit(TelemedicineLoaded(doctors));
        }
      },
      onError: (error) {
        emit(TelemedicineError(error.toString()));
      },
    );
  }

  void startWatchingSessions(String patientId) {
    _sessionsSubscription?.cancel();
    _sessionsSubscription = _repository.watchUserSessions(patientId).listen(
      (sessions) {
        if (state is TelemedicineLoaded) {
          final currentState = state as TelemedicineLoaded;
          emit(currentState.copyWith(activeSessions: sessions));
          
          // Schedule reminders for new scheduled sessions
          for (var session in sessions) {
            if (session['status'] == 'scheduled' && session['scheduled_time'] != null) {
              _scheduleNotificationReminder(session);
            }
          }
        }
      },
      onError: (error) {
        print("Error watching sessions: $error");
      }
    );
  }

  void _scheduleNotificationReminder(Map<String, dynamic> session) {
    final sessionId = session['id'].toString();
    if (_sessionReminders.containsKey(sessionId)) return;

    final scheduledTime = DateTime.parse(session['scheduled_time']);
    final reminderTime = scheduledTime.subtract(const Duration(minutes: 5));
    final now = DateTime.now();

    if (reminderTime.isAfter(now)) {
      final delay = reminderTime.difference(now);
      _sessionReminders[sessionId] = Timer(delay, () {
        getIt<NotificationService>().showNotification(
          title: "Tele-Consult Starting Soon",
          body: "Your session is starting in 5 minutes. Tap to join!",
          payload: sessionId,
        );
      });
      print("Scheduled reminder for session $sessionId in ${delay.inMinutes} mins");
    }
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
      return await _repository.checkBookingConflict(patientId, doctorId, startOfDay, endOfDay);
    } catch (e) {
      print("Error checking conflict: $e");
      return true;
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
    _sessionsSubscription?.cancel();
    _sessionReminders.values.forEach((timer) => timer.cancel());
    return super.close();
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/notification_service.dart';
import '../../../injector.dart';
import '../data/models/doctor_model.dart';
import '../data/models/telemedicine_service_model.dart';
import '../domain/repositories/i_telemedicine_repository.dart';

part 'telemedicine_state.dart';

/// [TelemedicineCubit] manages the state and logic for tele-consultation features.
///
/// **Responsibilities:**
/// 1. **Real-time Monitoring**: Subscribes to live updates for doctor availability and 
///    active/scheduled sessions using [ITelemedicineRepository].
/// 2. **Proactive Reminders**: Automatically schedules local notifications 5 minutes 
///    before a scheduled consultation begins.
/// 3. **Conflict Management**: Validates booking requests against existing appointments 
///    to prevent scheduling overlaps.
/// 4. **Session Initiation**: Orchestrates the process of starting new video calls 
///    and managing their lifecycle status (e.g., active, completed).
class TelemedicineCubit extends Cubit<TelemedicineState> {
  final ITelemedicineRepository _repository;
  StreamSubscription? _doctorsSubscription;
  StreamSubscription? _sessionsSubscription;
  
  /// In-memory storage for active timers used to trigger pre-session reminders.
  final Map<String, Timer> _sessionReminders = {};

  TelemedicineCubit(this._repository) : super(TelemedicineInitial());

  /// Begins a real-time subscription to the doctors list.
  /// Updates the [TelemedicineLoaded] state whenever a doctor's availability changes.
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

  /// Begins a real-time subscription to the user's active/scheduled consultations.
  /// Automatically calls [_scheduleNotificationReminder] for any upcoming appointments.
  void startWatchingSessions(String patientId) {
    _sessionsSubscription?.cancel();
    _sessionsSubscription = _repository.watchUserSessions(patientId).listen(
      (sessions) {
        if (state is TelemedicineLoaded) {
          final currentState = state as TelemedicineLoaded;
          emit(currentState.copyWith(activeSessions: sessions));
          
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

  /// Sets a [Timer] to show a push notification 5 minutes before the session's start time.
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

  /// Fetches specific availability slots for a given [doctorId].
  Future<List<Map<String, dynamic>>> getDoctorAvailability(String doctorId) async {
    try {
      return await _repository.getDoctorAvailability(doctorId);
    } catch (e) {
      print("Error fetching availability: $e");
      return [];
    }
  }

  /// Verifies if a user or doctor already has a booking at the specified [date].
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

  /// Loads symptoms categorized by a specific medical area (e.g., "General", "Reproductive").
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

  /// Creates a new consultation record and returns the call ID for video room initialization.
  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata, DateTime? scheduledTime}) async {
    try {
      return await _repository.initiateCall(patientId, doctorId, metadata: metadata, scheduledTime: scheduledTime);
    } catch (e) {
      throw Exception('Failed to initiate consultation: $e');
    }
  }

  /// Updates the state of an existing call (e.g., to 'completed' or 'cancelled').
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

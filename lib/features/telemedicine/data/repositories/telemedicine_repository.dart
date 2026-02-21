import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_model.dart';
import '../models/telemedicine_service_model.dart';
import '../../domain/repositories/i_telemedicine_repository.dart';

/// [TelemedicineRepository] provides a concrete implementation of [ITelemedicineRepository]
/// using Supabase as the backend.
///
/// It handles all data-related operations for the telemedicine feature, including:
/// - Watching for real-time updates on doctors and user sessions.
/// - Fetching static data like symptoms and service availability.
/// - Managing the lifecycle of tele-consultation sessions (initiation, status updates).
/// - Validating bookings to prevent scheduling conflicts.
class TelemedicineRepository implements ITelemedicineRepository {
  final SupabaseClient _supabase;

  TelemedicineRepository(this._supabase);

  /// Subscribes to a real-time stream of available doctors.
  ///
  /// Orders doctors by their online status to prioritize those who are active.
  /// Returns a [Stream] of [DoctorModel] lists.
  @override
  Stream<List<DoctorModel>> watchDoctors() {
    return _supabase
        .from('telemed_doctors')
        .stream(primaryKey: ['id'])
        .order('is_online', ascending: false)
        .map((data) => data.map((e) => DoctorModel.fromMap(e)).toList());
  }

  /// Fetches a list of common symptoms for a specified medical [category].
  ///
  /// Used to populate checklists in specialized consultation flows (e.g., General, Reproductive).
  @override
  Future<List<Map<String, dynamic>>> getSymptomsByCategory(String category) async {
    final response = await _supabase
        .from('telemed_symptoms')
        .select('name')
        .eq('category', category)
        .eq('is_active', true)
        .order('display_order', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Retrieves the available time slots for a specific [doctorId].
  @override
  Future<List<Map<String, dynamic>>> getDoctorAvailability(String doctorId) async {
    final response = await _supabase
        .from('doctor_availability')
        .select()
        .eq('doctor_id', doctorId)
        .eq('is_available', true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Retrieves a list of [TelemedicineService] offerings for a given [category].
  @override
  Future<List<TelemedicineService>> getServicesByCategory(String category) async {
    final response = await _supabase
        .from('telemedicine_services')
        .select()
        .eq('category', category)
        .eq('is_active', true);
    
    return (response as List).map((map) => TelemedicineService.fromMap(map)).toList();
  }

  /// Creates a new telemedicine session in the database.
  ///
  /// Sets the status to 'active' for immediate calls or 'scheduled' for future bookings.
  /// Returns the unique ID of the newly created session.
  @override
  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata, DateTime? scheduledTime}) async {
    final Map<String, dynamic> insertData = {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'status': scheduledTime == null ? 'active' : 'scheduled',
      'started_at': scheduledTime == null ? DateTime.now().toIso8601String() : null,
      'scheduled_time': scheduledTime?.toIso8601String(),
    };

    if (metadata != null) {
      insertData['metadata'] = metadata;
    }

    final response = await _supabase
        .from('telemed_sessions')
        .insert(insertData)
        .select()
        .single();
    
    return response['id'] as String;
  }

  /// Updates the status of an existing session identified by [callId].
  ///
  /// Common statuses include 'completed', 'cancelled', or 'missed'.
  @override
  Future<void> updateCallStatus(String callId, String status) async {
    await _supabase.from('telemed_sessions').update({'status': status}).eq('id', callId);
  }

  /// Subscribes to real-time changes for a single session identified by [callId].
  ///
  /// Useful for monitoring the status of a call room from multiple participants' devices.
  @override
  Stream<List<Map<String, dynamic>>> watchCall(String callId) {
    return _supabase
        .from('telemed_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', callId);
  }
  
  /// Subscribes to a real-time stream of a user's active and scheduled sessions.
  ///
  /// Filters out completed or cancelled sessions to only show relevant upcoming appointments.
  @override
  Stream<List<Map<String, dynamic>>> watchUserSessions(String patientId) {
    return _supabase
        .from('telemed_sessions')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('scheduled_time', ascending: true)
        .map((data) => data.where((session) {
              final status = session['status'];
              return status == 'scheduled' || status == 'active';
            }).toList());
  }

  /// Checks if a [patientId] already has a non-cancelled appointment with a
  /// specific [doctorId] within the given [startOfDay] and [endOfDay].
  ///
  /// Returns `true` if there is no conflict, `false` otherwise.
  @override
  Future<bool> checkBookingConflict(String patientId, String doctorId, DateTime startOfDay, DateTime endOfDay) async {
    final response = await _supabase
        .from('telemed_sessions')
        .select()
        .eq('patient_id', patientId)
        .eq('doctor_id', doctorId)
        .gte('scheduled_time', startOfDay.toIso8601String())
        .lte('scheduled_time', endOfDay.toIso8601String())
        .not('status', 'eq', 'cancelled');
    
    return (response as List).isEmpty;
  }

  /// Quickly checks if a [patientId] has any sessions with 'scheduled' or 'active' status.
  ///
  /// Returns `true` if active sessions exist, otherwise `false`.
  @override
  Future<bool> hasAnyActiveSessions(String patientId) async {
    final response = await _supabase
        .from('telemed_sessions')
        .select()
        .eq('patient_id', patientId)
        .filter('status', 'in', '("scheduled","active")')
        .limit(1);

    return (response as List).isNotEmpty;
  }
}

import '../../data/models/doctor_model.dart';
import '../../data/models/telemedicine_service_model.dart';

abstract class ITelemedicineRepository {
  Stream<List<DoctorModel>> watchDoctors();
  Future<List<TelemedicineService>> getServicesByCategory(String category);
  Future<List<Map<String, dynamic>>> getDoctorAvailability(String doctorId);
  Future<List<Map<String, dynamic>>> getSymptomsByCategory(String category);
  
  // Updated for Booking Flow & Scheduled Sessions
  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata, DateTime? scheduledTime});
  Future<void> updateCallStatus(String callId, String status);
  Stream<List<Map<String, dynamic>>> watchCall(String callId);
}

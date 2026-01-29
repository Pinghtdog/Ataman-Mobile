import '../../data/models/doctor_model.dart';
import '../../data/models/telemedicine_service_model.dart';

abstract class ITelemedicineRepository {
  Stream<List<DoctorModel>> watchDoctors();
  Future<List<TelemedicineService>> getServicesByCategory(String category);
  
  // Updated for ZegoCloud & Shared Sessions
  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata});
  Future<void> updateCallStatus(String callId, String status);
  Stream<List<Map<String, dynamic>>> watchCall(String callId);
}

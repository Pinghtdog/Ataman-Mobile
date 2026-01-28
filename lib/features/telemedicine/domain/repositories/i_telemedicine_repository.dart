import '../../data/models/doctor_model.dart';

abstract class ITelemedicineRepository {
  Stream<List<DoctorModel>> watchDoctors();
  Future<String> initiateCall(String patientId, String doctorId, {Map<String, dynamic>? metadata});
  Future<void> updateCallStatus(String callId, String status);
  
  // Signaling methods
  Future<void> addIceCandidate(String callId, Map<String, dynamic> candidate, String type);
  Future<void> updateCallOffer(String callId, Map<String, dynamic> offer);
  Future<void> updateCallAnswer(String callId, Map<String, dynamic> answer, String status);
  Stream<List<Map<String, dynamic>>> watchCall(String callId);
  Stream<List<Map<String, dynamic>>> watchIceCandidates(String callId);
}

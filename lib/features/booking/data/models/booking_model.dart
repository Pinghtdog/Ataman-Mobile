enum BookingStatus { pending, confirmed, completed, cancelled, missed }

class Booking {
  final String id;
  final String userId;
  final String facilityId;
  final String facilityName;
  final DateTime appointmentTime;
  final BookingStatus status;
  final String? triageResult;
  final String? triagePriority;
  final DateTime createdAt;
  final String? serviceId;
  final String? familyMemberId;
  
  // DOH FORM 2 Requirements
  final String natureOfVisit; // New Consultation/Case, New Admission, Follow-up visit
  final String? chiefComplaint;
  final String? referredFrom;
  final String? referredTo;

  Booking({
    required this.id,
    required this.userId,
    required this.facilityId,
    required this.facilityName,
    required this.appointmentTime,
    required this.status,
    this.triageResult,
    this.triagePriority,
    required this.createdAt,
    this.serviceId,
    this.familyMemberId,
    this.natureOfVisit = 'New Consultation/Case',
    this.chiefComplaint,
    this.referredFrom,
    this.referredTo,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      userId: json['user_id'],
      facilityId: json['facility_id'].toString(),
      facilityName: json['facility_name'] ?? 'Facility',
      appointmentTime: DateTime.parse(json['appointment_time']),
      status: _parseStatus(json['status']),
      triageResult: json['triage_result'],
      triagePriority: json['triage_priority'],
      createdAt: DateTime.parse(json['created_at']),
      serviceId: json['service_id']?.toString(),
      familyMemberId: json['family_member_id']?.toString(),
      natureOfVisit: json['nature_of_visit'] ?? 'New Consultation/Case',
      chiefComplaint: json['chief_complaint'],
      referredFrom: json['referred_from'],
      referredTo: json['referred_to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'facility_id': facilityId,
      'appointment_time': appointmentTime.toIso8601String(),
      'status': status.name,
      'triage_result': triageResult,
      'triage_priority': triagePriority,
      'service_id': serviceId,
      'family_member_id': familyMemberId,
      'nature_of_visit': natureOfVisit,
      'chief_complaint': chiefComplaint,
      'referred_from': referredFrom,
      'referred_to': referredTo,
    };
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed': return BookingStatus.confirmed;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelled;
      case 'missed': return BookingStatus.missed;
      default: return BookingStatus.pending;
    }
  }
}

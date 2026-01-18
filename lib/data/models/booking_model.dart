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

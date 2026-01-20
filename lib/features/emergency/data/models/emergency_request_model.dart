enum EmergencyStatus { pending, dispatched, arrived, completed, cancelled }
enum EmergencyType { sos, ambulance, accident, maternal, cardiac, other }

class EmergencyRequest {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final EmergencyType type;
  final EmergencyStatus status;
  final double latitude;
  final double longitude;
  final String? address;
  final String? assignedAmbulanceId;
  final DateTime createdAt;

  EmergencyRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.type,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    this.assignedAmbulanceId,
    required this.createdAt,
  });

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      id: json['id'].toString(),
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      userPhone: json['user_phone'] ?? '',
      type: _parseType(json['type']),
      status: _parseStatus(json['status']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      assignedAmbulanceId: json['assigned_ambulance_id']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'type': type.name,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'assigned_ambulance_id': assignedAmbulanceId,
    };
  }

  static EmergencyStatus _parseStatus(String? status) {
    return EmergencyStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => EmergencyStatus.pending,
    );
  }

  static EmergencyType _parseType(String? type) {
    return EmergencyType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => EmergencyType.other,
    );
  }
}

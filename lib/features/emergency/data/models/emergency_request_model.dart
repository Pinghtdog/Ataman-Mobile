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

  // AI Triage Data Bridge
  final String? aiSummary;
  final String? requiredCapability;
  final Map<String, dynamic>? soapNote;

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
    this.aiSummary,
    this.requiredCapability,
    this.soapNote,
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
      aiSummary: json['ai_summary'],
      requiredCapability: json['required_capability'],
      soapNote: json['soap_note'],
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
      'ai_summary': aiSummary,
      'required_capability': requiredCapability,
      'soap_note': soapNote,
    };
  }

  static EmergencyStatus _parseStatus(String? status) {
    return EmergencyStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => EmergencyStatus.pending,
    );
  }

  static EmergencyType _parseType(String? type) {
    if (type == null) return EmergencyType.other;
    // Map AI case categories to EmergencyType if possible
    final String typeStr = type.toLowerCase();
    if (typeStr.contains('maternal') || typeStr.contains('pregnancy')) return EmergencyType.maternal;
    if (typeStr.contains('cardiac') || typeStr.contains('heart')) return EmergencyType.cardiac;
    if (typeStr.contains('accident') || typeStr.contains('trauma')) return EmergencyType.accident;
    
    return EmergencyType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => EmergencyType.other,
    );
  }
}

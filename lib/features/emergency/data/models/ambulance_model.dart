class Ambulance {
  final String id;
  final String plateNumber;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final DateTime updatedAt;

  Ambulance({
    required this.id,
    required this.plateNumber,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    required this.updatedAt,
  });

  factory Ambulance.fromJson(Map<String, dynamic> json) {
    return Ambulance(
      id: json['id'],
      plateNumber: json['plate_number'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isAvailable: json['is_available'] ?? true,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

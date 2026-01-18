enum FacilityStatus { congested, available, closed }
enum FacilityType { hospital, bhc, clinic }

class Facility {
  final String id;
  final String name;
  final String address;
  final String? barangay;
  final FacilityStatus status;
  final FacilityType type;
  final int queueCount;
  final bool hasDoctor; 
  final String medsStatus;
  final double? latitude;
  final double? longitude;
  final bool isDiversionActive;
  final String distance;

  const Facility({
    required this.id,
    required this.name,
    required this.address,
    this.barangay,
    required this.status,
    required this.type,
    required this.queueCount,
    required this.hasDoctor,
    required this.medsStatus,
    this.latitude,
    this.longitude,
    this.isDiversionActive = false,
    this.distance = "Calculating...",
  });

  Facility copyWith({
    String? id,
    String? name,
    String? address,
    String? barangay,
    FacilityStatus? status,
    FacilityType? type,
    int? queueCount,
    bool? hasDoctor,
    String? medsStatus,
    double? latitude,
    double? longitude,
    bool? isDiversionActive,
    String? distance,
  }) {
    return Facility(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      barangay: barangay ?? this.barangay,
      status: status ?? this.status,
      type: type ?? this.type,
      queueCount: queueCount ?? this.queueCount,
      hasDoctor: hasDoctor ?? this.hasDoctor,
      medsStatus: medsStatus ?? this.medsStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDiversionActive: isDiversionActive ?? this.isDiversionActive,
      distance: distance ?? this.distance,
    );
  }

  factory Facility.fromJson(Map<String, dynamic> json) {
    FacilityStatus parseStatus(String? status) {
      if (status == 'congested') return FacilityStatus.congested;
      if (status == 'closed') return FacilityStatus.closed;
      return FacilityStatus.available;
    }

    FacilityType parseType(String? typeStr) {
      if (typeStr?.toLowerCase() == 'hospital') return FacilityType.hospital;
      if (typeStr?.toLowerCase() == 'clinic') return FacilityType.clinic;
      return FacilityType.bhc;
    }

    return Facility(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Facility',
      address: json['address'] ?? '',
      barangay: json['barangay'],
      status: parseStatus(json['status']),
      type: parseType(json['type']),
      queueCount: json['current_queue_length'] ?? 0,
      hasDoctor: json['has_doctor_on_site'] ?? false,
      medsStatus: json['meds_availability'] ?? 'Unknown',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDiversionActive: json['is_diversion_active'] ?? false,
      distance: 'Calculating...',
    );
  }
}

final List<Facility> mockFacilities = [
  const Facility(
    id: '1',
    name: "Naga City General Hospital",
    address: "Peñafrancia Ave., Naga City",
    type: FacilityType.hospital,
    status: FacilityStatus.congested,
    queueCount: 45,
    hasDoctor: true,
    medsStatus: "High Stock",
    isDiversionActive: true,
    distance: "3.2km",
  ),
  const Facility(
    id: '2',
    name: "Concepcion Pequeña BHC",
    address: "Near Plaza, Concepcion",
    type: FacilityType.bhc,
    status: FacilityStatus.available,
    queueCount: 4,
    hasDoctor: true,
    medsStatus: "Normal",
    distance: "0.8km",
  ),
  const Facility(
    id: '3',
    name: "Triangulo BHC",
    address: "Diversion Road, Triangulo",
    type: FacilityType.bhc,
    status: FacilityStatus.available,
    queueCount: 12,
    hasDoctor: false,
    medsStatus: "Low Stock",
    distance: "1.2km",
  ),
];

import 'facility_service_model.dart';

enum FacilityStatus { available, congested, closed }
enum FacilityType { hospital, bhc, clinic }
enum FacilityOwnership { governmentNational, governmentLgu, private, ngoCharitable }

enum FacilityCapability {
  barangayHealthStation,
  ruralHealthUnit,
  infirmary,
  hospitalLevel1,
  hospitalLevel2,
  hospitalLevel3,
  specializedCenter
}

class Facility {
  final String id;
  final String name;
  final String? shortCode;
  final String address;
  final String? barangay;
  final FacilityStatus status;
  final FacilityType type;
  final FacilityOwnership ownership;
  final FacilityCapability capability;
  final int queueCount;
  final bool hasDoctor; 
  final String medsStatus;
  final double? latitude;
  final double? longitude;
  final bool isDiversionActive;
  final bool isPhilHealthAccredited;
  final String? contactNumber;
  final String? email;
  final String? website;
  final String distance;
  final List<FacilityService> services;

  const Facility({
    required this.id,
    required this.name,
    this.shortCode,
    required this.address,
    this.barangay,
    required this.status,
    required this.type,
    required this.ownership,
    required this.capability,
    required this.queueCount,
    required this.hasDoctor,
    required this.medsStatus,
    this.latitude,
    this.longitude,
    this.isDiversionActive = false,
    this.isPhilHealthAccredited = false,
    this.contactNumber,
    this.email,
    this.website,
    this.distance = "Calculating...",
    this.services = const [],
  });

  String get estimatedWaitTime {
    if (status == FacilityStatus.closed) return "Closed";

    int minutesPerPatient = type == FacilityType.hospital ? 10 : 15;
    int totalMinutes = queueCount * minutesPerPatient;

    if (totalMinutes == 0) return "No wait";
    if (totalMinutes < 60) return "$totalMinutes mins";

    double hours = totalMinutes / 60;
    return "${hours.toStringAsFixed(1)} hrs";
  }

  String get queueStatus {
    if (queueCount < 5) return "Light";
    if (queueCount < 15) return "Moderate";
    return "Busy";
  }

  Facility copyWith({
    String? id,
    String? name,
    String? shortCode,
    String? address,
    String? barangay,
    FacilityStatus? status,
    FacilityType? type,
    FacilityOwnership? ownership,
    FacilityCapability? capability,
    int? queueCount,
    bool? hasDoctor,
    String? medsStatus,
    double? latitude,
    double? longitude,
    bool? isDiversionActive,
    bool? isPhilHealthAccredited,
    String? contactNumber,
    String? email,
    String? website,
    String? distance,
    List<FacilityService>? services,
  }) {
    return Facility(
      id: id ?? this.id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      address: address ?? this.address,
      barangay: barangay ?? this.barangay,
      status: status ?? this.status,
      type: type ?? this.type,
      ownership: ownership ?? this.ownership,
      capability: capability ?? this.capability,
      queueCount: queueCount ?? this.queueCount,
      hasDoctor: hasDoctor ?? this.hasDoctor,
      medsStatus: medsStatus ?? this.medsStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDiversionActive: isDiversionActive ?? this.isDiversionActive,
      isPhilHealthAccredited: isPhilHealthAccredited ?? this.isPhilHealthAccredited,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      distance: distance ?? this.distance,
      services: services ?? this.services,
    );
  }

  factory Facility.fromJson(Map<String, dynamic> json) {
    FacilityStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'congested': return FacilityStatus.congested;
        case 'closed': return FacilityStatus.closed;
        default: return FacilityStatus.available;
      }
    }

    FacilityType parseType(String? t) {
      if (t?.toLowerCase() == 'hospital') return FacilityType.hospital;
      if (t?.toLowerCase() == 'clinic') return FacilityType.clinic;
      return FacilityType.bhc;
    }

    FacilityOwnership parseOwnership(String? o) {
      switch (o?.toUpperCase()) {
        case 'GOVERNMENT_NATIONAL': return FacilityOwnership.governmentNational;
        case 'GOVERNMENT_LGU': return FacilityOwnership.governmentLgu;
        case 'PRIVATE': return FacilityOwnership.private;
        case 'NGO_CHARITABLE': return FacilityOwnership.governmentLgu; // Defaulting for simplicity
        default: return FacilityOwnership.governmentLgu;
      }
    }

    FacilityCapability parseCapability(String? capStr) {
      switch (capStr?.toUpperCase()) {
        case 'BARANGAY_HEALTH_STATION': return FacilityCapability.barangayHealthStation;
        case 'RURAL_HEALTH_UNIT': return FacilityCapability.ruralHealthUnit;
        case 'INFIRMARY': return FacilityCapability.infirmary;
        case 'HOSPITAL_LEVEL_1': return FacilityCapability.hospitalLevel1;
        case 'HOSPITAL_LEVEL_2': return FacilityCapability.hospitalLevel2;
        case 'HOSPITAL_LEVEL_3': return FacilityCapability.hospitalLevel3;
        case 'SPECIALIZED_CENTER': return FacilityCapability.specializedCenter;
        default: return FacilityCapability.barangayHealthStation;
      }
    }

    return Facility(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Facility',
      shortCode: json['short_code'],
      address: json['address'] ?? '',
      barangay: json['barangay'],
      status: parseStatus(json['status']),
      type: parseType(json['type']),
      ownership: parseOwnership(json['ownership']),
      capability: parseCapability(json['capability']),
      queueCount: json['current_queue_length'] ?? 0,
      hasDoctor: json['has_doctor_on_site'] ?? false,
      medsStatus: json['meds_availability'] ?? 'Unknown',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDiversionActive: json['is_diversion_active'] ?? false,
      isPhilHealthAccredited: json['is_philhealth_accredited'] ?? false,
      contactNumber: json['contact_number'],
      email: json['email'],
      website: json['website'],
      distance: 'Calculating...',
      services: (json['facility_services'] as List?)
          ?.map((s) => FacilityService.fromJson(s))
          .toList() ?? const [],
    );
  }
}

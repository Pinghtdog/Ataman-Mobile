class FacilityService {
  final String id;
  final String facilityId;
  final String name;
  final bool isAvailable;
  final String category;

  FacilityService({
    required this.id,
    required this.facilityId,
    required this.name,
    required this.isAvailable,
    required this.category,
  });

  factory FacilityService.fromJson(Map<String, dynamic> json) {
    return FacilityService(
      id: json['id'].toString(),
      facilityId: json['facility_id'].toString(),
      name: json['name'] ?? '',
      isAvailable: json['is_available'] ?? true,
      category: json['category'] ?? 'general',
    );
  }
}

import 'package:equatable/equatable.dart';

class ReferralPathway extends Equatable {
  final String id;
  final String originFacilityId;
  final String destinationFacilityId;
  final String destinationName;
  final String caseCategory;
  final String priorityLevel;
  final String? protocolNotes;

  const ReferralPathway({
    required this.id,
    required this.originFacilityId,
    required this.destinationFacilityId,
    required this.destinationName,
    required this.caseCategory,
    required this.priorityLevel,
    this.protocolNotes,
  });

  factory ReferralPathway.fromJson(Map<String, dynamic> json) {
    return ReferralPathway(
      id: json['id'],
      originFacilityId: json['origin_facility_id'].toString(),
      destinationFacilityId: json['destination_facility_id'].toString(),
      destinationName: json['destination_facility']?['name'] ?? 'Recommended Hospital',
      caseCategory: json['case_category'],
      priorityLevel: json['priority_level'],
      protocolNotes: json['protocol_notes'],
    );
  }

  @override
  List<Object?> get props => [id, originFacilityId, destinationFacilityId, caseCategory];
}

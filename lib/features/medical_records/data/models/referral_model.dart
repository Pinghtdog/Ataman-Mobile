import 'package:equatable/equatable.dart';

enum ReferralStatus { PENDING, ACCEPTED, REJECTED, COMPLETED, CANCELLED }

class Referral extends Equatable {
  final String id;
  final String referenceNumber;
  final String? patientId;
  final String originFacilityName;
  final String destinationFacilityName;
  final String chiefComplaint;
  final String? diagnosisImpression;
  final ReferralStatus status;
  final DateTime createdAt;

  const Referral({
    required this.id,
    required this.referenceNumber,
    this.patientId,
    required this.originFacilityName,
    required this.destinationFacilityName,
    required this.chiefComplaint,
    this.diagnosisImpression,
    required this.status,
    required this.createdAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    // Handle both direct column and joined object names
    String? originName = json['origin_facility_name'];
    if (originName == null && json['origin_facility'] != null) {
      originName = json['origin_facility']['name'];
    }

    String? destName = json['destination_facility_name'];
    if (destName == null && json['destination_facility'] != null) {
      destName = json['destination_facility']['name'];
    }

    return Referral(
      id: json['id'].toString(),
      referenceNumber: json['reference_number'] ?? 'REF-0000',
      patientId: json['patient_id'],
      originFacilityName: originName ?? 'Origin Facility',
      destinationFacilityName: destName ?? 'Destination Hospital',
      chiefComplaint: json['chief_complaint'] ?? 'General Consult',
      diagnosisImpression: json['diagnosis_impression'],
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  static ReferralStatus _parseStatus(String? status) {
    return ReferralStatus.values.firstWhere(
      (e) => e.name == status?.toUpperCase(),
      orElse: () => ReferralStatus.PENDING,
    );
  }

  @override
  List<Object?> get props => [id, referenceNumber, status, createdAt];
}

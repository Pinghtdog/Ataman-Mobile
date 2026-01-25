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
    return Referral(
      id: json['id'],
      referenceNumber: json['reference_number'] ?? '',
      patientId: json['patient_id'],
      originFacilityName: json['origin_facility']?['name'] ?? 'Origin Facility',
      destinationFacilityName: json['destination_facility']?['name'] ?? 'Destination Hospital',
      chiefComplaint: json['chief_complaint'] ?? '',
      diagnosisImpression: json['diagnosis_impression'],
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['created_at']),
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

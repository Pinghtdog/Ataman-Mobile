import 'package:equatable/equatable.dart';

class FamilyMember extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String relationship;
  final DateTime? birthDate;
  final String? medicalId;
  final String? gender;
  final bool isVerified;

  const FamilyMember({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.relationship,
    this.birthDate,
    this.medicalId,
    this.gender,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
    id, userId, fullName, relationship, birthDate, medicalId, gender, isVerified
  ];

  factory FamilyMember.fromJson(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'].toString(),
      userId: map['user_id'],
      fullName: map['full_name'] ?? '',
      relationship: map['relationship'] ?? '',
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      medicalId: map['medical_id'],
      gender: map['gender'],
      isVerified: map['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'relationship': relationship,
      'birth_date': birthDate?.toIso8601String(),
      'medical_id': medicalId,
      'gender': gender,
      'is_verified': isVerified,
    };
  }

  FamilyMember copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? relationship,
    DateTime? birthDate,
    String? medicalId,
    String? gender,
    bool? isVerified,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      birthDate: birthDate ?? this.birthDate,
      medicalId: medicalId ?? this.medicalId,
      gender: gender ?? this.gender,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

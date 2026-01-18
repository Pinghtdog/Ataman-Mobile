class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? birthDate;
  final String? barangay;
  final String? philhealthId;
  final String? fcmToken;
  final bool isProfileComplete;
  
  // health related fields
  final String? gender;
  final String? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? allergies;
  final String? medicalConditions;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.birthDate,
    this.barangay,
    this.philhealthId,
    this.fcmToken,
    this.isProfileComplete = false,
    this.gender,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.allergies,
    this.medicalConditions,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      phoneNumber: map['phone_number'],
      birthDate: map['birth_date'],
      barangay: map['barangay'],
      philhealthId: map['philhealth_id'],
      fcmToken: map['fcm_token'],
      isProfileComplete: map['is_profile_complete'] ?? false,
      gender: map['gender'],
      bloodType: map['blood_type'],
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      allergies: map['allergies'],
      medicalConditions: map['medical_conditions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'birth_date': birthDate,
      'barangay': barangay,
      'philhealth_id': philhealthId,
      'fcm_token': fcmToken,
      'is_profile_complete': isProfileComplete,
      'gender': gender,
      'blood_type': bloodType,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? birthDate,
    String? barangay,
    String? philhealthId,
    String? fcmToken,
    bool? isProfileComplete,
    String? gender,
    String? bloodType,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? allergies,
    String? medicalConditions,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      barangay: barangay ?? this.barangay,
      philhealthId: philhealthId ?? this.philhealthId,
      fcmToken: fcmToken ?? this.fcmToken,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
    );
  }
}

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffix;
  final String? maidenName;
  final String? phoneNumber;
  final String? birthDate;
  final String? birthplace;
  final String? motherName;
  final String? barangay;
  final String? residentialAddress;
  final String? philhealthId;
  final String? medicalId;
  final String? fcmToken;
  final bool isProfileComplete;
  
  // Health & Social related fields (DOH/UHC requirements)
  final String? gender;
  final String? bloodType;
  final String? civilStatus;
  final String? education;
  final String? employmentStatus;
  final bool is4psMember;
  final String? philhealthStatus; // Member or Dependent
  final String? familyPosition;   // Father, Mother, Son, etc.
  final bool isPcbMember;         // Primary Care Benefit
  
  // Emergency & Clinical
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? allergies;
  final String? medicalConditions;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.suffix,
    this.maidenName,
    this.phoneNumber,
    this.birthDate,
    this.birthplace,
    this.motherName,
    this.barangay,
    this.residentialAddress,
    this.philhealthId,
    this.medicalId,
    this.fcmToken,
    this.isProfileComplete = false,
    this.gender,
    this.bloodType,
    this.civilStatus,
    this.education,
    this.employmentStatus,
    this.is4psMember = false,
    this.philhealthStatus,
    this.familyPosition,
    this.isPcbMember = false,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.allergies,
    this.medicalConditions,
  });

  @override
  List<Object?> get props => [
    id, email, firstName, middleName, lastName, suffix, maidenName,
    phoneNumber, birthDate, birthplace, motherName, barangay,
    residentialAddress, philhealthId, medicalId, fcmToken, isProfileComplete,
    gender, bloodType, civilStatus, education, employmentStatus, is4psMember,
    philhealthStatus, familyPosition, isPcbMember, emergencyContactName,
    emergencyContactPhone, allergies, medicalConditions,
  ];

  // Computed property for UI display (PH Standard: First Middle Last)
  String get fullName {
    String name = firstName;
    if (middleName != null && middleName!.isNotEmpty) {
      name += " $middleName";
    }
    name += " $lastName";
    if (suffix != null && suffix!.isNotEmpty) {
      name += " $suffix";
    }
    return name;
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['first_name'] ?? '',
      middleName: map['middle_name'],
      lastName: map['last_name'] ?? '',
      suffix: map['suffix'],
      maidenName: map['maiden_name'],
      phoneNumber: map['phone_number'],
      birthDate: map['birth_date'],
      birthplace: map['birthplace'],
      motherName: map['mother_name'],
      barangay: map['barangay'],
      residentialAddress: map['residential_address'],
      philhealthId: map['philhealth_id'],
      medicalId: map['medical_id'],
      fcmToken: map['fcm_token'],
      isProfileComplete: map['is_profile_complete'] ?? false,
      gender: map['gender'],
      bloodType: map['blood_type'],
      civilStatus: map['civil_status'],
      education: map['educational_attainment'],
      employmentStatus: map['employment_status'],
      is4psMember: map['is_4ps_member'] ?? false,
      philhealthStatus: map['philhealth_status'],
      familyPosition: map['family_position'],
      isPcbMember: map['is_pcb_member'] ?? false,
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      allergies: map['allergies'],
      medicalConditions: map['medical_conditions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'suffix': suffix,
      'maiden_name': maidenName,
      'phone_number': phoneNumber,
      'birth_date': birthDate,
      'birthplace': birthplace,
      'mother_name': motherName,
      'barangay': barangay,
      'residential_address': residentialAddress,
      'philhealth_id': philhealthId,
      'medical_id': medicalId,
      'fcm_token': fcmToken,
      'is_profile_complete': isProfileComplete,
      'gender': gender,
      'blood_type': bloodType,
      'civil_status': civilStatus,
      'educational_attainment': education,
      'employment_status': employmentStatus,
      'is_4ps_member': is4psMember,
      'philhealth_status': philhealthStatus,
      'family_position': familyPosition,
      'is_pcb_member': isPcbMember,
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
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffix,
    String? maidenName,
    String? phoneNumber,
    String? birthDate,
    String? birthplace,
    String? motherName,
    String? barangay,
    String? residentialAddress,
    String? philhealthId,
    String? medicalId,
    String? fcmToken,
    bool? isProfileComplete,
    String? gender,
    String? bloodType,
    String? civilStatus,
    String? education,
    String? employmentStatus,
    bool? is4psMember,
    String? philhealthStatus,
    String? familyPosition,
    bool? isPcbMember,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? allergies,
    String? medicalConditions,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      maidenName: maidenName ?? this.maidenName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      birthplace: birthplace ?? this.birthplace,
      motherName: motherName ?? this.motherName,
      barangay: barangay ?? this.barangay,
      residentialAddress: residentialAddress ?? this.residentialAddress,
      philhealthId: philhealthId ?? this.philhealthId,
      medicalId: medicalId ?? this.medicalId,
      fcmToken: fcmToken ?? this.fcmToken,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      civilStatus: civilStatus ?? this.civilStatus,
      education: education ?? this.education,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      is4psMember: is4psMember ?? this.is4psMember,
      philhealthStatus: philhealthStatus ?? this.philhealthStatus,
      familyPosition: familyPosition ?? this.familyPosition,
      isPcbMember: isPcbMember ?? this.isPcbMember,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
    );
  }
}

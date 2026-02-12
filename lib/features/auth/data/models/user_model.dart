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
  final bool isPhilhealthVerified; 

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
    this.isPhilhealthVerified = false,
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
    isPhilhealthVerified, gender, bloodType, civilStatus, education, 
    employmentStatus, is4psMember, philhealthStatus, familyPosition, 
    isPcbMember, emergencyContactName, emergencyContactPhone, allergies, 
    medicalConditions,
  ];

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
    // Extra defensive check: If the key exists but is null, default to false.
    bool toBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return false;
    }

    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      middleName: map['middle_name']?.toString(),
      lastName: map['last_name']?.toString() ?? '',
      suffix: map['suffix']?.toString(),
      maidenName: map['maiden_name']?.toString(),
      phoneNumber: map['phone_number']?.toString(),
      birthDate: map['birth_date']?.toString(),
      birthplace: map['birthplace']?.toString(),
      motherName: map['mother_name']?.toString(),
      barangay: map['barangay']?.toString(),
      residentialAddress: map['residential_address']?.toString(),
      philhealthId: map['philhealth_id']?.toString(),
      medicalId: map['medical_id']?.toString(),
      fcmToken: map['fcm_token']?.toString(),
      isProfileComplete: toBool(map['is_profile_complete']),
      isPhilhealthVerified: toBool(map['is_philhealth_verified']),
      gender: map['gender']?.toString(),
      bloodType: map['blood_type']?.toString(),
      civilStatus: map['civil_status']?.toString(),
      education: map['educational_attainment']?.toString(),
      employmentStatus: map['employment_status']?.toString(),
      is4psMember: toBool(map['is_4ps_member']),
      philhealthStatus: map['philhealth_status']?.toString(),
      familyPosition: map['family_position']?.toString(),
      isPcbMember: toBool(map['is_pcb_member']),
      emergencyContactName: map['emergency_contact_name']?.toString(),
      emergencyContactPhone: map['emergency_contact_phone']?.toString(),
      allergies: map['allergies']?.toString(),
      medicalConditions: map['medical_conditions']?.toString(),
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
      'is_philhealth_verified': isPhilhealthVerified,
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
    bool? isPhilhealthVerified,
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
      isPhilhealthVerified: isPhilhealthVerified ?? this.isPhilhealthVerified,
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

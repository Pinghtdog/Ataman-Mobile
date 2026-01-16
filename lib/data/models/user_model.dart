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
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

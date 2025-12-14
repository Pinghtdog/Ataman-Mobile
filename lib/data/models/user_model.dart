class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.fcmToken,
  });

  // for firestore document conversion
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      fcmToken: data['fcmToken'],
    );
  }
  // to firestore document conversion
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'fcmToken': fcmToken,
      'userType': 'patient',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
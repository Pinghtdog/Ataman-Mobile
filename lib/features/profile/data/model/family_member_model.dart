class FamilyMember {
  final String id;
  final String userId;
  final String fullName;
  final String relationship;
  final int age;
  final bool isActiveAccount;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.relationship,
    this.age = 0,
    this.isActiveAccount = false,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'].toString(),
      userId: map['user_id'],
      fullName: map['full_name'] ?? '',
      relationship: map['relationship'] ?? '',
      age: map['age'] ?? 0,
      isActiveAccount: map['is_active_account'] ?? false,
    );
  }
}

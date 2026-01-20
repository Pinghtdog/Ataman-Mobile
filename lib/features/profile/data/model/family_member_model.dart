class FamilyMember {
  final String id;
  final String userId;
  final String fullName;
  final String relationship;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.relationship,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'].toString(),
      userId: json['user_id'],
      fullName: json['full_name'] ?? '',
      relationship: json['relationship'] ?? '',
    );
  }
}

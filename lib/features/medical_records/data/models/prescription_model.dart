class Prescription {
  final String id;
  final String userId;
  final String medicationName;
  final String dosage;
  final String doctorName;
  final DateTime validUntil;
  final String? instructions;
  final DateTime createdAt;

  Prescription({
    required this.id,
    required this.userId,
    required this.medicationName,
    required this.dosage,
    required this.doctorName,
    required this.validUntil,
    this.instructions,
    required this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      userId: json['user_id'],
      medicationName: json['medication_name'],
      dosage: json['dosage'],
      doctorName: json['doctor_name'],
      validUntil: DateTime.parse(json['valid_until']),
      instructions: json['instructions'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'medication_name': medicationName,
      'dosage': dosage,
      'doctor_name': doctorName,
      'valid_until': validUntil.toIso8601String(),
      'instructions': instructions,
    };
  }
}

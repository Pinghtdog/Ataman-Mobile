class Prescription {
  final String id;
  final String medicationName;
  final String dosage;
  final String doctorName;
  final DateTime validUntil;

  Prescription({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.doctorName,
    required this.validUntil,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      medicationName: json['medication_name'],
      dosage: json['dosage'],
      doctorName: json['doctor_name'],
      validUntil: DateTime.parse(json['valid_until']),
    );
  }
}

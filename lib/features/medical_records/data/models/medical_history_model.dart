enum MedicalRecordType { consultation, immunization, emergency, lab }

class MedicalHistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final MedicalRecordType type;
  final String? tag;
  final String? extraInfo;
  final bool hasPdf;

  MedicalHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    this.tag,
    this.extraInfo,
    this.hasPdf = false,
  });

  factory MedicalHistoryItem.fromMap(Map<String, dynamic> map) {
    return MedicalHistoryItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      date: DateTime.parse(map['date']),
      type: _parseType(map['type']),
      tag: map['tag'],
      extraInfo: map['extra_info'],
      hasPdf: map['has_pdf'] ?? false,
    );
  }

  static MedicalRecordType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'consultation': return MedicalRecordType.consultation;
      case 'immunization': return MedicalRecordType.immunization;
      case 'emergency': return MedicalRecordType.emergency;
      case 'lab': return MedicalRecordType.lab;
      default: return MedicalRecordType.consultation;
    }
  }
}

class VideoCallModel {
  final String id;
  final String? doctorId;
  final String? patientId;
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
  final String status; // 'calling', 'active', 'ended', 'missed'
  final DateTime createdAt;

  VideoCallModel({
    required this.id,
    this.doctorId,
    this.patientId,
    this.offer,
    this.answer,
    required this.status,
    required this.createdAt,
  });

  factory VideoCallModel.fromMap(Map<String, dynamic> map) {
    return VideoCallModel(
      id: map['id'] as String,
      doctorId: map['doctor_id'] as String?,
      patientId: map['patient_id'] as String?,
      offer: map['offer'] as Map<String, dynamic>?,
      answer: map['answer'] as Map<String, dynamic>?,
      status: map['status'] as String? ?? 'calling',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctor_id': doctorId,
      'patient_id': patientId,
      'offer': offer,
      'answer': answer,
      'status': status,
    };
  }
}

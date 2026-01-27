class DoctorModel {
  final String id;
  final String? userId;
  final String fullName;
  final String specialty;
  final bool isOnline;
  final int currentWaitMinutes;

  DoctorModel({
    required this.id,
    this.userId,
    required this.fullName,
    required this.specialty,
    required this.isOnline,
    required this.currentWaitMinutes,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      fullName: map['full_name'] as String,
      specialty: map['specialty'] as String? ?? 'General Medicine',
      isOnline: map['is_online'] as bool? ?? false,
      currentWaitMinutes: map['current_wait_minutes'] as int? ?? 0,
    );
  }
}

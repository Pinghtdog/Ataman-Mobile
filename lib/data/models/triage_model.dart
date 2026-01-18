import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

enum TriageUrgency {
  emergency, // Red - Immediate action
  urgent,    // Yellow/Orange - Fast care
  nonUrgent, // Green - Standard care
}

class TriageResult {
  final String id;
  final String userId;
  final String rawSymptoms;
  final TriageUrgency urgency;
  final String specialty;
  final DateTime createdAt;

  TriageResult({
    required this.id,
    required this.userId,
    required this.rawSymptoms,
    required this.urgency,
    required this.specialty,
    required this.createdAt,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    return TriageResult(
      id: json['id'],
      userId: json['user_id'],
      rawSymptoms: json['raw_symptoms'],
      urgency: _parseUrgency(json['urgency']),
      specialty: json['specialty'] ?? 'General Medicine',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static TriageUrgency _parseUrgency(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'EMERGENCY':
        return TriageUrgency.emergency;
      case 'URGENT':
        return TriageUrgency.urgent;
      case 'NON_URGENT':
      default:
        return TriageUrgency.nonUrgent;
    }
  }

  Color get urgencyColor {
    switch (urgency) {
      case TriageUrgency.emergency:
        return AppColors.danger;
      case TriageUrgency.urgent:
        return AppColors.warning;
      case TriageUrgency.nonUrgent:
        return AppColors.success;
    }
  }

  String get actionText {
    switch (urgency) {
      case TriageUrgency.emergency:
        return "Call Emergency Services / Go to nearest ER";
      case TriageUrgency.urgent:
        return "Visit Urgent Care or Book an earlier appointment";
      case TriageUrgency.nonUrgent:
        return "Schedule a regular consultation";
    }
  }
}

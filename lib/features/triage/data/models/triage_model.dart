import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum TriageUrgency {
  emergency, // Red - Immediate action
  urgent,    // Yellow/Orange - Fast care
  nonUrgent, // Green - Standard care
}

enum TriageInputType {
  buttons,
  text,
}

class TriageStep {
  final String question;
  final List<String> options;
  final TriageInputType inputType;
  final bool isFinal;
  final TriageResult? result;

  TriageStep({
    required this.question,
    this.options = const [],
    this.inputType = TriageInputType.buttons,
    this.isFinal = false,
    this.result,
  });

  factory TriageStep.fromJson(Map<String, dynamic> json) {
    return TriageStep(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      inputType: json['input_type'] == 'TEXT' ? TriageInputType.text : TriageInputType.buttons,
      isFinal: json['is_final'] ?? false,
      result: json['result'] != null ? TriageResult.fromJson(json['result']) : null,
    );
  }
}

class TriageResult {
  final String? id;
  final String? userId;
  final String rawSymptoms;
  final TriageUrgency urgency;
  final String specialty;
  final String? reason;
  final DateTime? createdAt;

  TriageResult({
    this.id,
    this.userId,
    required this.rawSymptoms,
    required this.urgency,
    required this.specialty,
    this.reason,
    this.createdAt,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    return TriageResult(
      id: json['id'],
      userId: json['user_id'],
      rawSymptoms: json['raw_symptoms'] ?? '',
      urgency: _parseUrgency(json['urgency']),
      specialty: json['specialty'] ?? 'General Medicine',
      reason: json['reason'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
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

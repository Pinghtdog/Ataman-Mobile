import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum TriageUrgency {
  emergency,
  urgent,
  routine,
}

enum TriageInputType {
  buttons,
  text,
}

class TriageStep extends Equatable {
  final String question;
  final List<String> options;
  final TriageInputType inputType;
  final String? placeholder;
  final bool isFinal;
  final TriageResult? result;

  const TriageStep({
    required this.question,
    this.options = const [],
    this.inputType = TriageInputType.buttons,
    this.placeholder,
    this.isFinal = false,
    this.result,
  });

  factory TriageStep.fromJson(Map<String, dynamic> json) {
    final bool isFinal = json['is_final'] ?? false;
    
    return TriageStep(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      inputType: json['input_type'] == 'TEXT' ? TriageInputType.text : TriageInputType.buttons,
      placeholder: json['placeholder'],
      isFinal: isFinal,
      // Only parse result if is_final is true, to avoid null pointer exceptions
      result: (isFinal && json['result'] != null) ? TriageResult.fromJson(json['result']) : null,
    );
  }

  @override
  List<Object?> get props => [question, options, inputType, placeholder, isFinal, result];
}

class TriageResult extends Equatable {
  final String? id;
  final String? userId;
  final String rawSymptoms;
  final TriageUrgency urgency;
  final String caseCategory;
  final String recommendedAction;
  final String requiredCapability;
  final bool isTelemedSuitable;
  final double aiConfidence;
  final String specialty;
  final String? reason;
  final String? summaryForProvider;
  final SoapNote? soapNote;
  final DateTime? createdAt;

  const TriageResult({
    this.id,
    this.userId,
    required this.rawSymptoms,
    required this.urgency,
    required this.caseCategory,
    required this.recommendedAction,
    required this.requiredCapability,
    required this.isTelemedSuitable,
    required this.aiConfidence,
    required this.specialty,
    this.reason,
    this.summaryForProvider,
    this.soapNote,
    this.createdAt,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    SoapNote? soap;
    if (json['soap_subjective'] != null || json['soap_note'] != null) {
      if (json['soap_note'] != null) {
        soap = SoapNote.fromJson(json['soap_note']);
      } else {
        soap = SoapNote(
          subjective: json['soap_subjective'] ?? '',
          objective: json['soap_objective'] ?? '',
          assessment: json['soap_assessment'] ?? '',
          plan: json['soap_plan'] ?? '',
        );
      }
    }

    return TriageResult(
      id: json['id'],
      userId: json['user_id'],
      rawSymptoms: json['raw_symptoms'] ?? '',
      urgency: _parseUrgency(json['urgency']),
      caseCategory: json['case_category'] ?? 'GENERAL_MEDICINE',
      recommendedAction: json['recommended_action'] ?? 'TELEMEDICINE',
      requiredCapability: json['required_capability'] ?? 'BARANGAY_HEALTH_STATION',
      isTelemedSuitable: json['is_telemed_suitable'] ?? false,
      aiConfidence: (json['ai_confidence'] ?? 0.0).toDouble(),
      specialty: json['specialty'] ?? 'General Medicine',
      reason: json['reason'],
      summaryForProvider: json['summary_for_provider'],
      soapNote: soap,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  static TriageUrgency _parseUrgency(dynamic urgency) {
    if (urgency == null) return TriageUrgency.routine;
    
    final String urgencyStr = urgency.toString().toUpperCase();
    switch (urgencyStr) {
      case 'EMERGENCY':
        return TriageUrgency.emergency;
      case 'URGENT':
        return TriageUrgency.urgent;
      case 'ROUTINE':
      case 'NON_URGENT':
      default:
        return TriageUrgency.routine;
    }
  }

  Color get urgencyColor {
    switch (urgency) {
      case TriageUrgency.emergency:
        return AppColors.danger;
      case TriageUrgency.urgent:
        return AppColors.warning;
      case TriageUrgency.routine:
        return AppColors.success;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        rawSymptoms,
        urgency,
        caseCategory,
        recommendedAction,
        requiredCapability,
        isTelemedSuitable,
        aiConfidence,
        specialty,
        reason,
        summaryForProvider,
        soapNote,
        createdAt
      ];
}

class SoapNote extends Equatable {
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;

  const SoapNote({
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
  });

  factory SoapNote.fromJson(Map<String, dynamic> json) {
    return SoapNote(
      subjective: json['subjective'] ?? '',
      objective: json['objective'] ?? '',
      assessment: json['assessment'] ?? '',
      plan: json['plan'] ?? '',
    );
  }

  @override
  List<Object?> get props => [subjective, objective, assessment, plan];
}

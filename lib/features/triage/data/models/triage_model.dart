import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// [TriageUrgency] defines the severity levels of a medical assessment.
enum TriageUrgency {
  /// Requires immediate medical attention (e.g., life-threatening conditions).
  emergency,
  /// Requires prompt medical attention but is not immediately life-threatening.
  urgent,
  /// Standard medical consultation without immediate time sensitivity.
  routine,
}

/// [TriageInputType] specifies how the user should interact with a triage step.
enum TriageInputType {
  /// The user selects from a list of predefined [options].
  buttons,
  /// The user provides a free-text description.
  text,
}

/// [TriageStep] represents a single interaction in the AI-driven triage flow.
class TriageStep extends Equatable {
  /// The question or prompt provided by the AI.
  final String question;
  /// A list of predefined answers for [TriageInputType.buttons].
  final List<String> options;
  /// The expected interaction method for this step.
  final TriageInputType inputType;
  /// Helper text for the input field in [TriageInputType.text].
  final String? placeholder;
  /// Indicates if this is the concluding step of the triage session.
  final bool isFinal;
  /// The final assessment result, populated only if [isFinal] is true.
  final TriageResult? result;

  const TriageStep({
    required this.question,
    this.options = const [],
    this.inputType = TriageInputType.buttons,
    this.placeholder,
    this.isFinal = false,
    this.result,
  });

  /// Creates a [TriageStep] from a JSON map provided by the AI service.
  factory TriageStep.fromJson(Map<String, dynamic> json) {
    final bool isFinal = json['is_final'] ?? false;
    
    return TriageStep(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      inputType: json['input_type'] == 'TEXT' ? TriageInputType.text : TriageInputType.buttons,
      placeholder: json['placeholder'],
      isFinal: isFinal,
      result: (isFinal && json['result'] != null) ? TriageResult.fromJson(json['result']) : null,
    );
  }

  @override
  List<Object?> get props => [question, options, inputType, placeholder, isFinal, result];
}

/// [TriageResult] contains the detailed outcome of a completed triage session.
class TriageResult extends Equatable {
  /// Unique identifier for the stored result record.
  final String? id;
  /// The ID of the user who performed the triage.
  final String? userId;
  /// A consolidated summary of the symptoms described during the session.
  final String rawSymptoms;
  /// The determined severity of the case.
  final TriageUrgency urgency;
  /// The clinical category of the case (e.g., RESPIRATORY, CARDIAC).
  final String caseCategory;
  /// The primary action recommended by the AI (e.g., AMBULANCE, CLINIC_VISIT).
  final String recommendedAction;
  /// The type of facility required to handle this case (e.g., BHC, HOSPITAL_L1).
  final String requiredCapability;
  /// Whether this case can be handled via a virtual consultation.
  final bool isTelemedSuitable;
  /// The AI's confidence level in its assessment (0.0 to 1.0).
  final double aiConfidence;
  /// The medical specialty most relevant to the symptoms.
  final String specialty;
  /// A plain-language explanation of why the AI reached its conclusion.
  final String? reason;
  /// A professional-grade summary meant for a healthcare provider.
  final String? summaryForProvider;
  /// Clinical SOAP (Subjective, Objective, Assessment, Plan) documentation.
  final SoapNote? soapNote;
  /// The timestamp of when the assessment was finalized.
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

  /// Constructs a [TriageResult] from database or AI service JSON.
  /// 
  /// Handles various SOAP note formats and ensures fallback values for required fields.
  factory TriageResult.fromJson(Map<String, dynamic> json) {
    SoapNote? soap;
    
    // Check individual columns first as they are more reliable in this setup
    final String subj = json['soap_subjective'] ?? '';
    final String obj = json['soap_objective'] ?? '';
    final String assess = json['soap_assessment'] ?? '';
    final String plan = json['soap_plan'] ?? '';

    if (subj.isNotEmpty || obj.isNotEmpty || assess.isNotEmpty || plan.isNotEmpty) {
      soap = SoapNote(
        subjective: subj,
        objective: obj,
        assessment: assess,
        plan: plan,
      );
    } else if (json['soap_note'] != null && json['soap_note'] is Map) {
      // Fallback to JSONB field if individual columns are empty
      final soapData = json['soap_note'] as Map<String, dynamic>;
      if (soapData.isNotEmpty) {
        soap = SoapNote.fromJson(soapData);
      }
    }

    return TriageResult(
      id: json['id']?.toString(),
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

  /// Normalizes urgency strings from the AI into [TriageUrgency] constants.
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

  /// Returns the semantic [Color] associated with the urgency of this result.
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

/// [SoapNote] follows the standard medical documentation format.
class SoapNote extends Equatable {
  /// Patient's reported symptoms and history.
  final String subjective;
  /// Observable findings (not typically used in remote triage but reserved for provider use).
  final String objective;
  /// The AI's clinical impression or diagnosis.
  final String assessment;
  /// Recommended treatment steps or follow-up actions.
  final String plan;

  const SoapNote({
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
  });

  /// Constructs a [SoapNote] from a JSON map, supporting multiple key naming conventions.
  factory SoapNote.fromJson(Map<String, dynamic> json) {
    return SoapNote(
      subjective: json['subjective'] ?? json['soap_subjective'] ?? '',
      objective: json['objective'] ?? json['soap_objective'] ?? '',
      assessment: json['assessment'] ?? json['soap_assessment'] ?? '',
      plan: json['plan'] ?? json['soap_plan'] ?? '',
    );
  }

  @override
  List<Object?> get props => [subjective, objective, assessment, plan];
}

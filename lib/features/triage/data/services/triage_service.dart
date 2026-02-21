import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/ai_service.dart';
import '../models/triage_model.dart';

/// [TriageService] orchestrates the AI-driven medical triage process and its data persistence.
///
/// It acts as the primary coordinator between the [AiService] (which provides the
/// diagnostic logic) and Supabase (which handles the storage of results and history).
///
/// **Responsibilities:**
/// 1.  **Conversational Logic**: Managing multi-turn sessions where the AI asks follow-up questions.
/// 2.  **Data Persistence**: Saving finalized assessments into the `triage_results` table.
/// 3.  **Automated Referrals**: Creating pending referral records for non-routine cases.
/// 4.  **Medical Timeline Integration**: Updating the user's `medical_history` with triage outcomes.
class TriageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AiService _aiService;

  TriageService(this._aiService);

  /// Initializes a triage session. Currently acts as a placeholder for future
  /// session-specific backend setup or logging.
  Future<void> initializeSession() async {
    print('DEBUG: TriageService initializing session...');
  }

  /// Fetches the next interaction step from the AI based on the current [history].
  ///
  /// Takes a list of [history] maps containing previous questions and answers.
  /// If the AI determines the assessment is complete, it triggers [_saveAndReturnResult].
  /// Otherwise, it returns a [TriageStep] with the next question and options.
  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    try {
      String prompt;
      if (history.isEmpty) {
        prompt = "New triage session. Start now.";
      } else {
        prompt = "Continue Triage. \n";
        final recentHistory = history.length > 5 ? history.sublist(history.length - 5) : history;
        for (var turn in recentHistory) {
          prompt += "Q: ${turn['question']} A: ${turn['answer']}\n";
        }
        prompt += "Next:";
      }

      final data = await _aiService.getTriageResponse(prompt);
      if (data['is_final'] == true && data['result'] != null) {
        return await _saveAndReturnResult(data['result'], history);
      }
      return TriageStep.fromJson(data);
    } catch (e, stackTrace) {
      developer.log('TRIAGE_SERVICE_ERROR: $e', name: 'TriageService', error: e, stackTrace: stackTrace);
      throw Exception('Triage Interrupted. Please try again.');
    }
  }

  /// Performs a one-shot triage assessment based on provided [symptoms].
  ///
  /// Useful for quick analysis or starting a triage process from a single text block.
  /// Automatically saves the result upon completion.
  Future<TriageResult> performTriage(String symptoms) async {
    try {
      final prompt = "SYMPTOMS: $symptoms";
      final data = await _aiService.getTriageResponse(prompt);
      if (data['result'] != null) {
        final step = await _saveAndReturnResult(data['result'], [{'question': 'Symptoms', 'answer': symptoms}]);
        return step.result!;
      }
      throw Exception('Failed to perform triage');
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the authenticated user's historical triage records.
  ///
  /// Returns a list of [TriageResult] objects ordered by creation date (newest first).
  Future<List<TriageResult>> getTriageHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    final response = await _supabase.from('triage_results').select().eq('user_id', user.id).order('created_at', ascending: false);
    return (response as List).map((json) => TriageResult.fromJson(json)).toList();
  }

  /// Persists the final AI assessment into the database and triggers secondary workflows.
  ///
  /// **Workflow:**
  /// 1.  Saves the full assessment to `triage_results`.
  /// 2.  Extracts and formats SOAP (Subjective, Objective, Assessment, Plan) data.
  /// 3.  If urgency is not 'ROUTINE', creates a record in the `referrals` table.
  /// 4.  Creates a summary entry in the `medical_history` table.
  Future<TriageStep> _saveAndReturnResult(Map<String, dynamic> resultData, List<Map<String, String>> history) async {
    final user = _supabase.auth.currentUser;
    try {
      if (user != null) {
        String historySummary = history.map((e) => "Q: ${e['question']} A: ${e['answer']}").join("\n");
        
        // Extract SOAP data from any possible structure the AI returns
        final dynamic rawSoap = resultData['soap_note'];
        Map<String, String> soapMap = {};
        
        if (rawSoap is Map) {
          soapMap = {
            'subjective': (rawSoap['subjective'] ?? resultData['soap_subjective'] ?? '').toString(),
            'objective': (rawSoap['objective'] ?? resultData['soap_objective'] ?? '').toString(),
            'assessment': (rawSoap['assessment'] ?? resultData['soap_assessment'] ?? '').toString(),
            'plan': (rawSoap['plan'] ?? resultData['soap_plan'] ?? '').toString(),
          };
        } else {
          soapMap = {
            'subjective': (resultData['soap_subjective'] ?? '').toString(),
            'objective': (resultData['soap_objective'] ?? '').toString(),
            'assessment': (resultData['soap_assessment'] ?? '').toString(),
            'plan': (resultData['soap_plan'] ?? '').toString(),
          };
        }

        final insertData = {
          'user_id': user.id,
          'raw_symptoms': historySummary,
          'urgency': resultData['urgency'],
          'case_category': resultData['case_category'],
          'recommended_action': resultData['recommended_action'],
          'required_capability': resultData['required_capability'],
          'is_telemed_suitable': resultData['is_telemed_suitable'] ?? false,
          'ai_confidence': resultData['ai_confidence'] ?? 0.0,
          'specialty': resultData['specialty'],
          'reason': resultData['reason'],
          'summary_for_provider': resultData['summary_for_provider'],
          // Save to individual columns
          'soap_subjective': soapMap['subjective'],
          'soap_objective': soapMap['objective'],
          'soap_assessment': soapMap['assessment'],
          'soap_plan': soapMap['plan'],
          // Also save to the JSONB column for redundancy
          'soap_note': soapMap,
        };

        final savedResult = await _supabase.from('triage_results').insert(insertData).select().single();

        if (resultData['urgency'] != 'ROUTINE') {
          try {
            await _supabase.from('referrals').insert({
              'patient_id': user.id,
              'chief_complaint': resultData['reason'] ?? (history.isNotEmpty ? history.first['answer'] : 'Triage Assessment'),
              'diagnosis_impression': soapMap['assessment']!.isNotEmpty ? soapMap['assessment'] : resultData['case_category'],
              'status': 'PENDING',
              'ai_priority_score': (resultData['ai_confidence'] ?? 0.0).toDouble(),
            });
          } catch (refError) {
            developer.log('REFERRAL_INSERT_ERROR: $refError', name: 'TriageService');
          }
        }

        await _supabase.from('medical_history').insert({
          'user_id': user.id,
          'title': "Triage: ${resultData['case_category']?.toString().replaceAll('_', ' ') ?? 'Consultation'}",
          'subtitle': resultData['specialty'] ?? 'General Medicine',
          'date': DateTime.now().toIso8601String(),
          'type': 'consultation',
          'tag': resultData['urgency'],
          'extra_info': resultData['recommended_action']?.toString().replaceAll('_', ' '),
          'has_pdf': false,
        });

        return TriageStep(
          question: "Complete", 
          options: const [], 
          isFinal: true, 
          result: TriageResult.fromJson(savedResult)
        );
      }
    } catch (e) { 
      developer.log('DATABASE_SAVE_ERROR: $e', name: 'TriageService');
    }
    
    return TriageStep(
      question: "Complete", 
      options: const [], 
      isFinal: true,
      result: TriageResult.fromJson(resultData)
    );
  }
}

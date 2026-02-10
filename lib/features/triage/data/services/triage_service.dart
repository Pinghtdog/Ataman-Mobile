import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/ai_service.dart';
import '../models/triage_model.dart';

class TriageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AiService _aiService;

  TriageService(this._aiService);

  Future<void> initializeSession() async {
    // Optional: could re-add profile context fetching here if desired
  }

  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    try {
      String prompt;
      if (history.isEmpty) {
        prompt = "New triage session. Start now.";
      } else {
        prompt = "Continue Triage. \n";
        final recentHistory = history.length > 3 ? history.sublist(history.length - 3) : history;
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
    } catch (e) {
      throw Exception('Triage Interrupted. Please try again.');
    }
  }

  Future<TriageResult> performTriage(String symptoms) async {
    final prompt = "SYMPTOMS: $symptoms";
    final data = await _aiService.getTriageResponse(prompt);
    if (data['result'] != null) {
      final step = await _saveAndReturnResult(data['result'], [{'question': 'Symptoms', 'answer': symptoms}]);
      return step.result!;
    }
    throw Exception('Failed to perform triage');
  }

  Future<List<TriageResult>> getTriageHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    final response = await _supabase.from('triage_results').select().eq('user_id', user.id).order('created_at', ascending: false);
    return (response as List).map((json) => TriageResult.fromJson(json)).toList();
  }

  Future<TriageStep> _saveAndReturnResult(Map<String, dynamic> resultData, List<Map<String, String>> history) async {
    final user = _supabase.auth.currentUser;
    try {
      if (user != null) {
        String historySummary = history.map((e) => "Q: ${e['question']} A: ${e['answer']}").join("\n");
        final soapNote = resultData['soap_note'];
        
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
        };

        final savedResult = await _supabase.from('triage_results').insert(insertData).select().single();

        final resultWithSoap = Map<String, dynamic>.from(savedResult);
        if (soapNote != null) {
          resultWithSoap['soap_subjective'] = soapNote['subjective'];
          resultWithSoap['soap_objective'] = soapNote['objective'];
          resultWithSoap['soap_assessment'] = soapNote['assessment'];
          resultWithSoap['soap_plan'] = soapNote['plan'];
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

        return TriageStep(question: "Complete", options: [], isFinal: true, result: TriageResult.fromJson(resultWithSoap));
      }
    } catch (e) { print("DB Error: $e"); }
    
    return TriageStep(question: "Complete", options: [], isFinal: true, result: TriageResult.fromJson(resultData));
  }
}

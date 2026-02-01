import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../models/triage_model.dart';

class TriageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _geminiService;

  TriageService(this._geminiService);

  Future<void> initializeSession() async {
    // No longer fetching profile context to reduce prompt size and avoid overloads
  }

  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    try {
      String prompt;
      if (history.isEmpty) {
        prompt = "${GeminiService.triageSystemPrompt}\nStart now.";
      } else {
        prompt = "Continue Triage. Output JSON ONLY. Format: {\"is_final\":false,\"question\":\"...\",\"options\":[]} OR {\"is_final\":true,\"result\":{...}}\n";
        final recentHistory = history.length > 3 ? history.sublist(history.length - 3) : history;
        for (var turn in recentHistory) {
          prompt += "Q: ${turn['question']} A: ${turn['answer']}\n";
        }
        prompt += "Next:";
      }

      final data = await _geminiService.getTriageResponse(prompt);

      if (data['is_final'] == true && data['result'] != null) {
        return await _saveAndReturnResult(data['result'], history);
      }
      return TriageStep.fromJson(data);
    } catch (e) {
      throw Exception('Triage Interrupted. Please try again.');
    }
  }

  Future<TriageResult> performTriage(String symptoms) async {
    final prompt = "${GeminiService.triageSystemPrompt}\nSYMPTOMS: $symptoms\nFinal JSON:";
    final data = await _geminiService.getTriageResponse(prompt);
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
        
        // 1. Save to triage_results
        final savedResult = await _supabase.from('triage_results').insert({
          'user_id': user.id,
          'raw_symptoms': historySummary,
          'urgency': resultData['urgency'],
          'case_category': resultData['case_category'],
          'recommended_action': resultData['recommended_action'],
          'required_capability': resultData['required_capability'],
          'is_telemed_suitable': resultData['is_telemed_suitable'],
          'ai_confidence': resultData['ai_confidence'],
          'specialty': resultData['specialty'],
          'reason': resultData['reason'],
          'summary_for_provider': resultData['summary_for_provider'],
          'soap_subjective': soapNote?['subjective'],
          'soap_objective': soapNote?['objective'],
          'soap_assessment': soapNote?['assessment'],
          'soap_plan': soapNote?['plan'],
        }).select().single();

        // 2. ALSO Save to medical_history table (to keep it populated)
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

        return TriageStep(question: "Complete", options: [], isFinal: true, result: TriageResult.fromJson(savedResult));
      }
    } catch (e) { print("DB Error: $e"); }
    return TriageStep(question: "Complete", options: [], isFinal: true, result: TriageResult.fromJson(resultData));
  }
}

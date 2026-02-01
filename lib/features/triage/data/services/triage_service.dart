import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../models/triage_model.dart';

class TriageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _geminiService;
  String? _cachedUserContext;

  TriageService(this._geminiService);

  Future<void> initializeSession() async {
    _cachedUserContext = null;
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase.from('users').select('birth_date, gender, medical_conditions, allergies, barangay')
          .eq('id', user.id).maybeSingle();
      if (data != null) {
        final age = data['birth_date'] != null ? _calculateAge(DateTime.parse(data['birth_date'])) : "Unk";
        _cachedUserContext = "PATIENT: ${data['gender']}, $age. History: ${data['medical_conditions']}.";
      }
    } catch (e) {
      _cachedUserContext = "PATIENT: Unknown.";
    }
  }

  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    try {
      String prompt;
      if (history.isEmpty) {
        // FIRST TURN: Send full instructions and patient context
        prompt = "${GeminiService.triageSystemPrompt}\nCONTEXT: ${_cachedUserContext ?? "None"}\nStart now.";
      } else {
        // FOLLOW-UPS: Ultra-Lite instructions. No patient context (it's in the flow history).
        prompt = "Continue Triage. Output JSON ONLY. Format: {\"is_final\":false,\"question\":\"...\",\"options\":[]} OR {\"is_final\":true,\"result\":{...}}\n";
        
        // SLIDING WINDOW: Reduce to 3 turns for max token saving
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
    final prompt = "${GeminiService.triageSystemPrompt}\nCONTEXT: $_cachedUserContext\nSYMPTOMS: $symptoms\nFinal JSON:";
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

        return TriageStep(question: "Complete", options: [], isFinal: true, result: TriageResult.fromJson(savedResult));
      }
    } catch (e) { print("DB Error: $e"); }
    return TriageStep(question: "Complete", options: [], isFinal: true, result: TriageResult.fromJson(resultData));
  }

  String _calculateAge(DateTime birthDate) {
    DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) age--;
    return age.toString();
  }
}

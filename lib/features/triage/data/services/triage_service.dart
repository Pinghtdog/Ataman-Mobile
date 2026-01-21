import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../auth/domain/repositories/i_user_repository.dart';
import '../models/triage_model.dart';

class TriageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _geminiService;
  final IUserRepository _userRepository;

  TriageService(this._geminiService, this._userRepository);

  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    try {
      final user = _supabase.auth.currentUser;
      String userContext = "";
      
      if (user != null) {
        final profile = await _userRepository.getUserProfile(user.id);
        if (profile != null) {
          userContext = "USER CONTEXT: Patient is ${profile.fullName}. ";
          if (profile.birthDate != null) {
            userContext += "Age/BirthDate: ${profile.birthDate}. ";
          }
          userContext += "Adjust urgency thresholds based on this profile.\n\n";
        }
      }

      String prompt = "${GeminiService.triageSystemPrompt}\n\n$userContext"
          "CONVERSATION HISTORY:\n";
          
      if (history.isEmpty) {
        prompt += "No history. Start with a broad question using BUTTONS to find the main issue.";
      } else {
        for (var turn in history) {
          prompt += "Q: ${turn['question']} | A: ${turn['answer']}\n";
        }
        prompt += "\nProvide the next step (BUTTONS or TEXT) or the final result.";
      }

      final data = await _geminiService.getTriageResponse(prompt);

      if (data['is_final'] == true && data['result'] != null) {
        String historySummary = history.map((e) => "Q: ${e['question']} A: ${e['answer']}").join("\n");
        final resultData = data['result'];
        
        if (user != null) {
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
          
          return TriageStep(
            question: "Triage Complete",
            options: [],
            isFinal: true,
            result: TriageResult.fromJson(savedResult),
          );
        }
      }

      return TriageStep.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get triage step: $e');
    }
  }

  Future<TriageResult> performTriage(String symptoms) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final profile = await _userRepository.getUserProfile(user.id);
      String userContext = profile != null 
          ? "USER CONTEXT: Patient profile data provided. Adjust urgency.\n\n" 
          : "";

      final prompt = "${GeminiService.triageSystemPrompt}\n\n$userContext"
          "User symptoms: $symptoms\n\nProvide the final result immediately.";
      final data = await _geminiService.getTriageResponse(prompt);
      
      final resultData = data['is_final'] == true ? data['result'] : data;
      final soapNote = resultData['soap_note'];

      final result = await _supabase.from('triage_results').insert({
        'user_id': user.id,
        'raw_symptoms': symptoms,
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

      return TriageResult.fromJson(result);
    } catch (e) {
      throw Exception('Failed to perform triage: $e');
    }
  }

  Future<List<TriageResult>> getTriageHistory() async {
    final response = await _supabase
        .from('triage_results')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => TriageResult.fromJson(json)).toList();
  }
}

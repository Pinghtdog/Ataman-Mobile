import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../auth/domain/repositories/i_user_repository.dart';
import '../models/triage_model.dart';

class TriageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _geminiService;
  final IUserRepository _userRepository;

  TriageService(this._geminiService, this._userRepository);

  /// Handles the multi-step triage process. 
  /// Updates or creates a session in triage_records.
  Future<TriageStep> getNextStep(List<Map<String, String>> history, {String? sessionId}) async {
    try {
      final user = _supabase.auth.currentUser;
      Map<String, dynamic>? userProfileData;
      
      if (user != null) {
        final profile = await _userRepository.getUserProfile(user.id);
        if (profile != null) {
          userProfileData = profile.toJson();
        }
      }

      // Fetch infrastructure context for AI-guided routing
      final List<dynamic> facilitiesData = await _supabase
          .from('facilities')
          .select('name, status, is_diversion_active, current_queue_length, has_doctor_on_site, facility_services(name, is_available)');
      
      final List<Map<String, dynamic>> liveFacilities = facilitiesData.map((f) {
        return {
          'name': f['name'],
          'status': f['status'],
          'is_diversion_active': f['is_diversion_active'],
          'queue': f['current_queue_length'],
          'has_doctor': f['has_doctor_on_site'],
          'services': f['facility_services'],
        };
      }).toList();

      String historyText = "";
      for (var turn in history) {
        historyText += "Q: ${turn['question']} | A: ${turn['answer']}\n";
      }

      final String lastAnswer = history.isNotEmpty ? history.last['answer']! : "Start Triage";

      final aiResponse = await _geminiService.getTriageResponse(
        userMessage: lastAnswer,
        history: historyText,
        stepCount: history.length + 1,
        userProfile: userProfileData,
        liveFacilities: liveFacilities,
      );

      // Handle session persistence in triage_records
      if (user != null) {
        final Map<String, dynamic> recordData = {
          'user_id': user.id,
          'status': aiResponse['is_final'] == true ? 'completed' : 'active',
          'current_step': history.length + 1,
          'interaction_history': history,
        };

        if (aiResponse['is_final'] == true && aiResponse['result'] != null) {
          final resultData = aiResponse['result'];
          final soapNote = resultData['soap_note'];
          String historySummary = history.map((e) => "Q: ${e['question']} A: ${e['answer']}").join("\n");
          
          recordData.addAll({
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
            'soap_note': soapNote,
            'completed_at': DateTime.now().toIso8601String(),
          });
        }

        if (sessionId != null) {
          await _supabase.from('triage_records').update(recordData).eq('id', sessionId);
        } else {
          // If it's a new session, create the record and get the ID back
          final newRecord = await _supabase.from('triage_records').insert(recordData).select('id').single();
          // Note: In a real app, you'd pass this sessionId back to the state
        }
      }

      if (aiResponse['is_final'] == true && aiResponse['result'] != null) {
        return TriageStep(
          question: "Triage Complete",
          options: [],
          isFinal: true,
          result: TriageResult.fromJson(aiResponse['result']),
        );
      }

      return TriageStep.fromJson(aiResponse);
    } catch (e) {
      throw Exception('Failed to get triage step: $e');
    }
  }

  /// Bypass for direct text-based triage
  Future<TriageResult> performTriage(String symptoms) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final profile = await _userRepository.getUserProfile(user.id);
      
      final List<dynamic> facilitiesData = await _supabase
          .from('facilities')
          .select('name, status, is_diversion_active, current_queue_length, has_doctor_on_site, facility_services(name, is_available)');
      
      final List<Map<String, dynamic>> liveFacilities = facilitiesData.map((f) {
        return {
          'name': f['name'],
          'status': f['status'],
          'is_diversion_active': f['is_diversion_active'],
          'services': f['facility_services'],
        };
      }).toList();

      final data = await _geminiService.getTriageResponse(
        userMessage: symptoms,
        history: "Direct triage bypass.",
        stepCount: 7,
        userProfile: profile?.toJson(),
        liveFacilities: liveFacilities,
      );
      
      final resultData = data['is_final'] == true ? data['result'] : data;

      final result = await _supabase.from('triage_records').insert({
        'user_id': user.id,
        'status': 'completed',
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
        'soap_note': resultData['soap_note'],
        'completed_at': DateTime.now().toIso8601String(),
      }).select().single();

      return TriageResult.fromJson(result);
    } catch (e) {
      throw Exception('Failed to perform triage: $e');
    }
  }

  Future<List<TriageResult>> getTriageHistory() async {
    final response = await _supabase
        .from('triage_records')
        .select()
        .eq('status', 'completed')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => TriageResult.fromJson(json)).toList();
  }
}

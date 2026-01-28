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
      Map<String, dynamic>? userProfileData;
      
      if (user != null) {
        final profile = await _userRepository.getUserProfile(user.id);
        if (profile != null) {
          userProfileData = profile.toMap();
        }
      }

      // FETCH LIVE INFRASTRUCTURE CONTEXT
      // Fetching facilities along with their operational services to give AI full visibility
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

      final data = await _geminiService.getTriageResponse(
        userMessage: lastAnswer,
        history: historyText,
        stepCount: history.length + 1,
        userProfile: userProfileData,
        liveFacilities: liveFacilities,
      );

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
      
      // Fetch live context for direct triage as well
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
        userProfile: profile?.toMap(),
        liveFacilities: liveFacilities,
      );
      
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

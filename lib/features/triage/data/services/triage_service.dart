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
    // HARDCODED LOGIC FOR DEMO/VIDEO PURPOSES (Fever and Coughing)
    await Future.delayed(const Duration(seconds: 1)); // Simulate AI thinking

    if (history.isEmpty) {
      return const TriageStep(
        question: "Maogmang aga! I am ATAMAN AI, your smart health assistant. How are you feeling today? Please select the option that best describes your concern.",
        options: ["Fever or Cough", "Body Aches or Pain", "Injury or Wound", "General Check-up", "Other symptoms"],
        inputType: TriageInputType.buttons,
        isFinal: false,
      );
    }

    if (history.length == 1) {
      return const TriageStep(
        question: "How long have you been experiencing these symptoms?",
        options: ["Just today", "2-3 days", "More than a week"],
        inputType: TriageInputType.buttons,
        isFinal: false,
      );
    }

    if (history.length == 2) {
      return const TriageStep(
        question: "Are you experiencing any difficulty in breathing, chest pain, or severe weakness?",
        options: ["Yes, I have difficulty breathing", "No, I don't have these symptoms"],
        inputType: TriageInputType.buttons,
        isFinal: false,
      );
    }

    // FINAL STEP: Generate a hardcoded result based on common patterns
    final String duration = history[1]['answer'] ?? "Unknown";
    final String breathing = history[2]['answer'] ?? "Normal";
    bool isUrgent = breathing.contains("Yes") || duration.contains("week");

    final mockResult = {
      'urgency': isUrgent ? 'URGENT' : 'ROUTINE',
      'case_category': 'GENERAL_MEDICINE',
      'recommended_action': isUrgent ? 'HOSPITAL_ER' : 'BHC_APPOINTMENT',
      'required_capability': isUrgent ? 'NCGH' : 'BHS',
      'is_telemed_suitable': !isUrgent,
      'ai_confidence': 0.98,
      'specialty': 'General Medicine / Internal Medicine',
      'reason': isUrgent ? 'Potential respiratory distress or prolonged symptoms detected.' : 'Symptoms appear stable but require evaluation.',
      'summary_for_provider': 'Patient reports ${history[0]['answer']}. Duration: $duration. Emergency signs: $breathing.',
      'soap_note': {
        'subjective': 'Patient complains of fever and cough for $duration. Signs of respiratory distress: $breathing.',
        'objective': 'Patient is alert but appearing fatigued. Temperature elevated (mock 38.5C). Cough is productive.',
        'assessment': 'Acute Respiratory Infection. Differential Diagnosis: Influenza-like Illness, possible Community Acquired Pneumonia.',
        'plan': isUrgent 
          ? 'Immediate referral to NCGH for chest X-ray and physical assessment. Monitor oxygen saturation.' 
          : 'Supportive care at home. Hydration, Paracetamol for fever. Follow up at Barangay Health Station if symptoms persist beyond 48 hours.',
      }
    };

    return await _saveAndReturnResult(mockResult, history);
  }

  Future<TriageResult> performTriage(String symptoms) async {
    final mockResult = {
      'urgency': 'ROUTINE',
      'case_category': 'GENERAL_MEDICINE',
      'recommended_action': 'TELEMEDICINE',
      'required_capability': 'BHS',
      'is_telemed_suitable': true,
      'ai_confidence': 0.8,
      'specialty': 'General Medicine',
      'reason': 'Symptoms reported via direct text.',
      'summary_for_provider': 'Symptoms: $symptoms',
    };
    final step = await _saveAndReturnResult(mockResult, [{'question': 'Symptoms', 'answer': symptoms}]);
    return step.result!;
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
        
        // Use a map for insertion to allow flexibility if columns are missing
        final insertData = {
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
        };

        // Note: We avoid inserting soap_subjective etc. into DB here if columns are missing
        // but we still pass them to the TriageResult object for the UI to display.
        
        final savedResult = await _supabase.from('triage_results').insert(insertData).select().single();

        // Add the soap notes manually to the returned object so the UI shows them
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
    
    // Fallback for UI if DB fails
    return TriageStep(question: "Complete", options: [], isFinal: true, result: TriageResult.fromJson(resultData));
  }
}

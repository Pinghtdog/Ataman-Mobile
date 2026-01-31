import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../models/triage_model.dart';

class TriageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeminiService _geminiService;

  // CACHE: Stores the user profile string so we don't query the DB on every step
  String? _cachedUserContext;

  TriageService(this._geminiService);

  /// 1. CALL THIS ONCE when the Triage Session starts
  Future<void> initializeSession() async {
    _cachedUserContext = null;
    final user = _supabase.auth.currentUser;

    if (user != null) {
      try {
        final data = await _supabase.from('users').select('''
          birth_date, 
          gender, 
          medical_conditions, 
          allergies, 
          barangay
        ''').eq('id', user.id).maybeSingle();

        if (data != null) {
          final dob = data['birth_date'] as String?;
          final age = dob != null ? _calculateAge(DateTime.parse(dob)) : "Unknown";
          final gender = data['gender'] ?? "Unknown";
          final conditions = data['medical_conditions'] ?? "None";
          final allergies = data['allergies'] ?? "None";
          final barangay = data['barangay'] ?? "Naga City";

          _cachedUserContext =
          "PATIENT CONTEXT: Gender: $gender. Age: $age. Location: $barangay. "
              "Pre-existing Conditions: $conditions. Allergies: $allergies.";
        }
      } catch (e) {
        print("Error loading profile: $e");
        _cachedUserContext = "PATIENT CONTEXT: Unknown.";
      }
    }
  }

  /// 2. Get Next Step with Token Optimization
  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    try {
      final userContext = _cachedUserContext ?? "PATIENT CONTEXT: Unknown.";
      String instructions;

      // --- OPTIMIZATION LOGIC ---
      if (history.isEmpty) {
        // STEP 1: Send the Full System Prompt
        instructions = "${GeminiService.triageSystemPrompt}\n\n$userContext";
      } else {
        // STEP 2+: Send "Lite" Instructions to save tokens/reduce overload
        instructions = '''
        Role: ATAMAN Triage. Continue assessment. 
        REMINDER: Output STRICT JSON only. 
        Format: {"is_final": false, "question": "...", "options": [...]} 
        OR {"is_final": true, "result": {...}}
        $userContext
        ''';
      }

      String prompt = "$instructions\n\nCONVERSATION HISTORY:\n";

      if (history.isEmpty) {
        prompt += "Start with a broad question using BUTTONS.";
      } else {
        // SLIDING WINDOW: Only send the last 5 turns to prevent context overflow
        final recentHistory = history.length > 5 ? history.sublist(history.length - 5) : history;

        for (var turn in recentHistory) {
          prompt += "Q: ${turn['question']} | A: ${turn['answer']}\n";
        }
        prompt += "\nBased on the above, provide the NEXT JSON step.";
      }

      final data = await _geminiService.getTriageResponse(prompt);

      if (data['is_final'] == true && data['result'] != null) {
        return await _saveAndReturnResult(data['result'], history);
      }

      return TriageStep.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get triage step: $e');
    }
  }

  Future<TriageResult> performTriage(String symptoms) async {
    // This is for a one-shot triage if needed, though getNextStep is preferred for conversational
    final userContext = _cachedUserContext ?? "PATIENT CONTEXT: Unknown.";
    final prompt = "${GeminiService.triageSystemPrompt}\n\n$userContext\n\nSYMPTOMS: $symptoms\n\nProvide the final assessment JSON immediately.";
    
    final data = await _geminiService.getTriageResponse(prompt);
    
    if (data['result'] != null) {
      final step = await _saveAndReturnResult(data['result'], [{'question': 'Initial Symptoms', 'answer': symptoms}]);
      return step.result!;
    }
    throw Exception('Failed to perform one-shot triage');
  }

  Future<List<TriageResult>> getTriageHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('triage_results')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

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

        return TriageStep(
          question: "Triage Complete",
          options: [],
          isFinal: true,
          result: TriageResult.fromJson(savedResult),
        );
      }
    } catch (e) {
      print("Failed to save result to DB: $e");
    }

    return TriageStep(
        question: "Triage Complete",
        options: [],
        isFinal: true,
        result: TriageResult.fromJson(resultData)
    );
  }

  String _calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }
}

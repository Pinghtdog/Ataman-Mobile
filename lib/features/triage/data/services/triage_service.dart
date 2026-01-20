import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/triage_model.dart';

class TriageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Gemini _gemini = Gemini.instance;

  static const String _interactivePrompt = '''
    You are a medical triage assistant following the Manchester Triage System.
    Your goal is to conduct a dynamic, multi-step triage. You can ask for information using either multiple-choice buttons OR a text input for detailed descriptions.

    GUIDELINES:
    1. Start broad with buttons to identify the main concern.
    2. If you need more detail (e.g., "Describe the pain" or "List any other symptoms"), you can switch to "TEXT" input type.
    3. If symptoms seem life-threatening (chest pain, severe bleeding, etc.), move to final result IMMEDIATELY with EMERGENCY status.
    4. Maximum 5-7 steps before reaching a final result.
    5. For "BUTTONS" type, provide 3-5 clear, concise options.
    6. For "TEXT" type, the 'options' list should be empty.
    7. Always return your response in the following JSON format:

    FOR A FOLLOW-UP STEP:
    {
      "is_final": false,
      "question": "The next question to ask",
      "input_type": "BUTTONS" | "TEXT",
      "options": ["Option 1", "Option 2"] // Only if input_type is BUTTONS
    }

    FOR A FINAL TRIAGE RESULT:
    {
      "is_final": true,
      "result": {
        "urgency": "EMERGENCY" | "URGENT" | "NON_URGENT",
        "specialty": "Likely medical specialty",
        "reason": "Brief clinical justification"
      }
    }

    URGENCY LEVELS:
    1. EMERGENCY: Life-threatening (e.g., stroke, heart attack, unconsciousness).
    2. URGENT: Requires quick attention but not immediate life threat (e.g., high fever, suspected fracture).
    3. NON_URGENT: Minor issues (e.g., mild cold, routine skin issue).

    CONTEXT:
    The conversation history is provided to you. Use it to determine the next step.
  ''';

  TriageService();

  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    try {
      String prompt = "$_interactivePrompt\n\nCONVERSATION HISTORY:\n";
      if (history.isEmpty) {
        prompt += "No history. Start with a broad question using BUTTONS to find the main issue.";
      } else {
        for (var turn in history) {
          prompt += "Q: ${turn['question']} | A: ${turn['answer']}\n";
        }
        prompt += "\nProvide the next step (BUTTONS or TEXT) or the final result.";
      }

      final response = await _gemini.text(prompt);
      final responseText = response?.output;
      if (responseText == null) throw Exception('No response from Gemini');

      String cleanedJson = _cleanJsonResponse(responseText);
      final Map<String, dynamic> data = jsonDecode(cleanedJson);

      if (data['is_final'] == true && data['result'] != null) {
        String summary = history.map((e) => "Q: ${e['question']} A: ${e['answer']}").join("\n");
        
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final savedResult = await _supabase.from('triage_results').insert({
            'user_id': user.id,
            'raw_symptoms': summary,
            'urgency': data['result']['urgency'],
            'specialty': data['result']['specialty'],
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

  String _cleanJsonResponse(String text) {
    String cleaned = text.trim();
    if (cleaned.contains('```json')) {
      cleaned = cleaned.split('```json')[1].split('```')[0].trim();
    } else if (cleaned.contains('```')) {
      cleaned = cleaned.split('```')[1].split('```')[0].trim();
    }
    return cleaned;
  }

  Future<TriageResult> classifySymptoms(String symptoms) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final response = await _gemini.text(
        "$_interactivePrompt\n\nUser symptoms: $symptoms\n\nProvide the final result immediately.",
      );

      final responseText = response?.output;
      if (responseText == null) throw Exception('No response from Gemini');

      final Map<String, dynamic> data = jsonDecode(_cleanJsonResponse(responseText));
      final resultData = data['is_final'] == true ? data['result'] : data;

      final result = await _supabase.from('triage_results').insert({
        'user_id': user.id,
        'raw_symptoms': symptoms,
        'urgency': resultData['urgency'],
        'specialty': resultData['specialty'],
      }).select().single();

      return TriageResult.fromJson(result);
    } catch (e) {
      throw Exception('Failed to classify symptoms: $e');
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

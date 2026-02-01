import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  final Gemini _gemini = Gemini.instance;

  // Optimized for Gemini Free Tier (Minimized tokens)
  static const String triageSystemPrompt = '''
Role: Medical Triage (Naga, PH). Max 5 steps.
Goal: Categorize urgency & routing.
Urgency: ROUTINE (BHC), URGENT (<24h), EMERGENCY (ER).
Format (JSON ONLY):
{"is_final":bool,"question":"str","input_type":"BUTTONS|TEXT","options":[],"result":{"urgency":"ROUTINE|URGENT|EMERGENCY","case_category":"GENERAL|MATERNAL|TRAUMA|INFECTIOUS|RENAL|BITE|MENTAL","recommended_action":"TELEMED|BHC|HOSPITAL_ER|AMBULANCE","required_capability":"BHS|INFIRMARY|H1|H2|H3","is_telemed_suitable":bool,"ai_confidence":0.0,"specialty":"str","reason":"str","summary_for_provider":"str","soap_note":{"subjective":"str","objective":"str","assessment":"str","plan":"str"}}}
''';

  Future<Map<String, dynamic>> getTriageResponse(String prompt) async {
    developer.log('GEMINI_REQUEST: $prompt', name: 'GeminiService');
    try {
      final response = await _gemini.prompt(parts: [Part.text(prompt)]);
      final text = response?.output;
      
      developer.log('GEMINI_RESPONSE_RAW: $text', name: 'GeminiService');
      
      if (text == null) {
        developer.log('GEMINI_ERROR: Empty response', name: 'GeminiService');
        throw Exception('No response');
      }
      
      final cleaned = _cleanJsonResponse(text);
      developer.log('GEMINI_RESPONSE_CLEANED: $cleaned', name: 'GeminiService');
      
      return jsonDecode(cleaned);
    } catch (e) {
      developer.log('GEMINI_EXCEPTION: $e', name: 'GeminiService', error: e);
      rethrow;
    }
  }

  String _cleanJsonResponse(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
    else if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
    if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
    return cleaned.trim();
  }
}

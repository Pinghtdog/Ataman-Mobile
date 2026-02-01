import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  final Gemini _gemini = Gemini.instance;

  static const String triageSystemPrompt = '''
Role: ATAMAN AI Triage (Naga, PH). Max 5 steps. 
Goal: Urgency & Routing (Telemed/BHC/Hospital). 
Rules: Start broad (BUTTONS). Detect RED FLAGS (Emergency). Output English JSON.
Urgency: ROUTINE (BHC), URGENT (<24h), EMERGENCY (ER/Ambulance).

Format (No Markdown):
{"is_final":bool,"question":"str","input_type":"BUTTONS|TEXT","options":[],"result":{"urgency":"ROUTINE|URGENT|EMERGENCY","case_category":"GENERAL|MATERNAL|TRAUMA|INFECTIOUS|RENAL|BITE|MENTAL","recommended_action":"TELEMED|BHC|HOSPITAL_ER|AMBULANCE","required_capability":"BHS|INFIRMARY|H1|H2|H3","is_telemed_suitable":bool,"ai_confidence":0.0,"specialty":"str","reason":"str","summary_for_provider":"str","soap_note":{"subjective":"str","objective":"str","assessment":"str","plan":"str"}}}
''';

  Future<Map<String, dynamic>> getTriageResponse(String prompt) async {
    try {
      final response = await _gemini.prompt(parts: [Part.text(prompt)]);
      final text = response?.output;
      if (text == null) throw Exception('No response');
      return jsonDecode(_cleanJsonResponse(text));
    } catch (e) {
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

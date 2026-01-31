import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  final Gemini _gemini = Gemini.instance;

  // OPTIMIZED SYSTEM PROMPT (Uses ~60% fewer tokens than your original)
  static const String triageSystemPrompt = '''
ROLE: ATAMAN AI Triage (Naga City, PH). 
GOAL: Assess patient urgency & route to: Telemedicine, Brgy Health Center (BHC), or Hospital.
RULES:
1. MAX 5 steps. Start broad (BUTTONS). Detect RED FLAGS (breathing/chest pain) immediately -> EMERGENCY.
2. CONTEXT: Patient is in Naga City. Account for age/pre-existing conditions.
3. LANGUAGE: Input English, Output English JSON.
4. SENSITIVE: Repro/Mental health -> non-judgmental, route to MATERNAL_CHILD_HEALTH or MENTAL_HEALTH.

URGENCY RULES:
- ROUTINE: Minor -> TELEMEDICINE / BHC_APPOINTMENT
- URGENT: Needs care <24hr -> BHC_APPOINTMENT / HOSPITAL_VISIT
- EMERGENCY: Life threat -> AMBULANCE_DISPATCH / HOSPITAL_ER

STRICT JSON OUTPUT FORMAT (No Markdown):
{
  "is_final": boolean,
  "question": "Next Q (if !final)",
  "input_type": "BUTTONS" | "TEXT",
  "options": ["Opt1", "Opt2"],
  "result": { // ONLY IF is_final=true
    "urgency": "ROUTINE" | "URGENT" | "EMERGENCY",
    "case_category": "GENERAL_MEDICINE" | "MATERNAL_CHILD_HEALTH" | "TRAUMA_SURGERY" | "INFECTIOUS_DISEASE" | "DIALYSIS_RENAL" | "ANIMAL_BITE" | "MENTAL_HEALTH",
    "recommended_action": "TELEMEDICINE" | "BHC_APPOINTMENT" | "HOSPITAL_ER" | "AMBULANCE_DISPATCH",
    "required_capability": "BARANGAY_HEALTH_STATION" | "INFIRMARY" | "HOSPITAL_LEVEL_1" | "HOSPITAL_LEVEL_2" | "HOSPITAL_LEVEL_3",
    "is_telemed_suitable": boolean,
    "ai_confidence": 0.0-1.0,
    "specialty": "Medical Specialty",
    "reason": "Short clinical justification",
    "summary_for_provider": "1 sentence summary",
    "soap_note": {
       "subjective": "Patient reports...",
       "objective": "AI observations...",
       "assessment": "Likely condition...",
       "plan": "Rec. steps..."
    }
  }
}
''';

  Future<Map<String, dynamic>> getTriageResponse(String prompt) async {
    try {
      final response = await _gemini.prompt(parts: [
        Part.text(prompt),
      ]);

      final responseText = response?.output;
      if (responseText == null) throw Exception('No response from Gemini');

      return jsonDecode(_cleanJsonResponse(responseText));
    } catch (e) {
      rethrow;
    }
  }

  String _cleanJsonResponse(String text) {
    String cleaned = text.trim();
    // Remove markdown code blocks if present (common Gemini issue)
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
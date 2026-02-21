import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

/// [GroqService] provides an implementation of [AiService] using the Groq Cloud API.
///
/// It leverages high-performance LLMs (like Llama 3) to power the ATAMAN AI Triage Engine,
/// specifically tailored for the healthcare infrastructure of Naga City, Philippines.
///
/// **Key Capabilities:**
/// 1. **AI Triage**: Guides users through a symptom-checking flow and recommends the 
///    appropriate level of care (BHC, Infirmary, or Hospital).
/// 2. **Medical Summarization**: Generates professional SOAP notes from raw consultation data.
/// 3. **Follow-up Planning**: Suggests clinical follow-up timeframes based on assessment notes.
class GroqService implements AiService {
  String? get _apiKey => dotenv.env['GROQ_API_KEY'];

  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.3-70b-versatile';

  /// The comprehensive system prompt that defines the AI's behavior, 
  /// knowledge of Naga City's health facilities, and the expected JSON output schema.
  static const String triageSystemPrompt = '''
    You are the ATAMAN AI Triage Engine for Naga City, Philippines.
    
    CORE RULES:
    1. SPEED: Keep responses short and direct.
    2. OPTIONS: ALWAYS include "None of the above / I want to describe it differently" as the LAST option in the `options` array.
    3. STEP LIMIT: Reach a decision by Step #7.

    FACILITY CAPABILITIES (Based on Naga Health Infrastructure):
    - BARANGAY_HEALTH_STATION (BHC): Primary care, PhilHealth Konsulta, vaccinations. (CHO I, CHO II).
    - INFIRMARY: Basic emergency and inpatient services.
    - HOSPITAL_LEVEL_1: Surgery, maternity, standard ER, preventive, rehabilitative, curative (e.g., NCGH).
    - HOSPITAL_LEVEL_2 / HOSPITAL_LEVEL_3: Specialized surgery, ICU, trauma (e.g., BMC).

    ROUTING LOGIC:
    - EMERGENCY: Severe trauma, chest pain, difficulty breathing -> HOSPITAL_ER (Level 2/3) + AMBULANCE_DISPATCH.
    - URGENT: High fever, suspected fractures, animal bites -> HOSPITAL_ER (Level 1) or INFIRMARY.
    - ROUTINE: Cold, mild pain, follow-ups -> BHC_APPOINTMENT or TELEMEDICINE.
    
    DIVERSION: If [DIVERSION ALERT] is present for a facility, recommend alternatives with the same or higher capability.

    OUTPUT FORMAT (STRICT JSON):
    {
      "is_final": boolean,
      "question": "string (user's language, mix of Tagalog and English)",
      "input_type": "BUTTONS" | "TEXT",
      "placeholder": "string (hint for text input, optional)",
      "options": ["string"],
      "result": {
        "urgency": "ROUTINE" | "URGENT" | "EMERGENCY",
        "case_category": "string",
        "recommended_action": "TELEMEDICINE" | "BHC_APPOINTMENT" | "HOSPITAL_ER" | "AMBULANCE_DISPATCH",
        "required_capability": "BARANGAY_HEALTH_STATION" | "INFIRMARY" | "HOSPITAL_LEVEL_1" | "HOSPITAL_LEVEL_2" | "HOSPITAL_LEVEL_3",
        "is_telemed_suitable": boolean,
        "ai_confidence": number,
        "specialty": "string",
        "reason": "string (English explanation of routing logic)",
        "summary_for_provider": "string",
        "soap_note": { 
          "subjective": "string", 
          "objective": "string (based on history)", 
          "assessment": "string", 
          "plan": "string" 
        }
      }
    }
  ''';

  @override
  Future<Map<String, dynamic>> getTriageResponse(String userPrompt) async {
    return _generateChatCompletion(triageSystemPrompt, userPrompt);
  }

  @override
  Future<Map<String, dynamic>> getFollowUpRecommendation(String notes) async {
    const prompt = "Based on these medical notes, suggest a follow-up timeframe and reason. Return JSON: { \"days_until_follow_up\": int, \"reason\": string }";
    return _generateChatCompletion(prompt, notes);
  }

  @override
  Future<Map<String, dynamic>> summarizeConsultation({
    required String transcriptOrNotes,
    required Map<String, dynamic> patientProfile,
  }) async {
    final prompt = "Patient: ${patientProfile['first_name']} ${patientProfile['last_name']}\nNotes: $transcriptOrNotes";
    const system = "Generate a professional SOAP note (Subjective, Objective, Assessment, Plan) in JSON format.";
    return _generateChatCompletion(system, prompt);
  }

  /// Sends a request to the Groq API and handles the response.
  /// 
  /// It enforces strict JSON output and handles common API errors such as 
  /// missing keys or malformed responses.
  Future<Map<String, dynamic>> _generateChatCompletion(String systemPrompt, String userPrompt) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      developer.log('GROQ_API_KEY is missing or empty', name: 'AiService');
      throw Exception('Groq API Key missing');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'stream': false,
          'temperature': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] ?? '';
        final extractedJson = _extractJson(text);
        
        try {
          return jsonDecode(extractedJson);
        } catch (e) {
          developer.log('Failed to parse JSON from Groq response: $text', name: 'AiService');
          throw Exception('Invalid JSON response from AI');
        }
      }
      
      final errorBody = response.body;
      developer.log('Groq API Error ${response.statusCode}: $errorBody', name: 'AiService');
      throw Exception('Groq Error ${response.statusCode}');
    } catch (e) {
      developer.log('GROQ_EXCEPTION: $e', name: 'AiService');
      rethrow;
    }
  }

  /// Extracts the JSON portion of a string response. 
  /// 
  /// This is a safety measure in case the AI includes conversational text 
  /// outside of the requested JSON block.
  String _extractJson(String text) {
    final RegExp jsonRegex = RegExp(r'(\{[\s\S]*\})');
    final match = jsonRegex.firstMatch(text);
    if (match != null) {
      return match.group(1) ?? text.trim();
    }
    return text.trim();
  }
}

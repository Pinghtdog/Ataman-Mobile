import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

class OpenAiService implements AiService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';

  static const String triageSystemPrompt = '''
Role: Medical Triage AI (Naga, PH). 
Goal: Assess urgency and routing.
Instructions: Output JSON ONLY. No text before or after.
Schema: {
  "is_final": bool,
  "question": "str",
  "options": ["str"],
  "result": {
    "urgency": "str",
    "case_category": "str",
    "recommended_action": "str",
    "required_capability": "str",
    "specialty": "str",
    "reason": "str",
    "summary_for_provider": "str",
    "is_telemed_suitable": bool,
    "ai_confidence": float
  }
}
''';

  static const String followUpSystemPrompt = '''
Role: Medical Scheduler AI. Suggest a follow-up appointment date and reason based on consultation notes.
Instructions: Output JSON ONLY. 
Schema: {"days_until_follow_up":int,"reason":"str","urgency":"str"}
''';

  static const String soapNoteSystemPrompt = '''
Role: Medical Scribe AI. Generate a professional SOAP note (Subjective, Objective, Assessment, Plan) from consultation notes.
Instructions: Output JSON ONLY.
Schema: {"subjective":"str","objective":"str","assessment":"str","plan":"str"}
''';

  @override
  Future<Map<String, dynamic>> getTriageResponse(String userPrompt) async {
    return _generateChatCompletion(triageSystemPrompt, userPrompt);
  }

  @override
  Future<Map<String, dynamic>> getFollowUpRecommendation(String notes) async {
    return _generateChatCompletion(followUpSystemPrompt, "Consultation Notes: $notes");
  }

  @override
  Future<Map<String, dynamic>> summarizeConsultation({
    required String transcriptOrNotes,
    required Map<String, dynamic> patientProfile,
  }) async {
    final prompt = "Patient: ${patientProfile['full_name']}\nNotes: $transcriptOrNotes";
    return _generateChatCompletion(soapNoteSystemPrompt, prompt);
  }

  Future<Map<String, dynamic>> _generateChatCompletion(String systemPrompt, String userPrompt) async {
    if (_apiKey == null) throw Exception('OpenAI API Key missing in .env');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'];
        if (text == null) throw Exception('AI returned empty content');
        return jsonDecode(text);
      }

      throw Exception('OpenAI Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      developer.log('OPENAI_EXCEPTION: $e', name: 'OpenAiService');
      rethrow;
    }
  }
}

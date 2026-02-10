import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

class GeminiService implements AiService {
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  
  // Using v1 instead of v1beta for better stability
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';

  static const String triageSystemPrompt = '''
Role: Medical Triage AI. Naga, PH. Output JSON ONLY.
Schema: {"is_final":bool,"question":"str","options":["str"],"result":{"urgency":"str","case_category":"str","recommended_action":"str","required_capability":"str","specialty":"str","reason":"str","summary_for_provider":"str"}}
''';

  static const String assignmentSystemPrompt = '''
Role: Emergency Dispatch AI.
Goal: Optimize ambulance assignment based on distance, traffic, and vehicle capability.
Instructions: Output JSON ONLY.
Schema: {"recommended_ambulance_id":"str","estimated_arrival_minutes":int,"reasoning":"str","alternative_options":[{"id":"str","eta":int}]}
''';

  @override
  Future<Map<String, dynamic>> getTriageResponse(String userPrompt) async {
    return _generateContent(triageSystemPrompt, userPrompt);
  }

  @override
  Future<Map<String, dynamic>> getFollowUpRecommendation(String notes) async {
    const prompt = 'Role: Medical Scheduler. Suggest follow-up. JSON: {"days_until_follow_up":int,"reason":"str"}';
    return _generateContent(prompt, notes);
  }

  @override
  Future<Map<String, dynamic>> summarizeConsultation({
    required String transcriptOrNotes,
    required Map<String, dynamic> patientProfile,
  }) async {
    const prompt = 'Role: Medical Scribe. Generate SOAP note JSON: {"subjective":"str","objective":"str","assessment":"str","plan":"str"}';
    return _generateContent(prompt, "Patient: ${patientProfile['full_name']}\nNotes: $transcriptOrNotes");
  }

  Future<Map<String, dynamic>> getAmbulanceAssignment(String prompt) async {
    return _generateContent(assignmentSystemPrompt, prompt);
  }

  Future<Map<String, dynamic>> _generateContent(String systemPrompt, String userPrompt) async {
    if (_apiKey == null) throw Exception('Gemini API Key missing');

    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': "$systemPrompt\n\n$userPrompt"}]}],
          'generationConfig': {
            'temperature': 0.1,
            'response_mime_type': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?[0]?['parts']?[0]?['text'];
        return jsonDecode(_extractJson(text));
      }
      throw Exception('Gemini Error ${response.statusCode}');
    } catch (e) {
      developer.log('GEMINI_EXCEPTION: $e', name: 'GeminiService');
      rethrow;
    }
  }

  String _extractJson(String text) {
    final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
    final match = jsonRegex.firstMatch(text);
    return match?.group(0) ?? text.trim();
  }
}

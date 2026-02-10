import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

class GrokService implements AiService {
  final String? _apiKey = dotenv.env['GROK_API_KEY'];
  static const String _baseUrl = 'https://api.x.ai/v1/chat/completions';
  static const String _model = 'grok-4-latest';

  static const String triageSystemPrompt = '''
Role: Medical Triage AI (Naga, PH). 
Goal: Assess urgency and routing.
Instructions: Output JSON ONLY.
Schema matches OpenAI service.
''';

  @override
  Future<Map<String, dynamic>> getTriageResponse(String userPrompt) async {
    return _generateChatCompletion(triageSystemPrompt, userPrompt);
  }

  @override
  Future<Map<String, dynamic>> getFollowUpRecommendation(String notes) async {
    return _generateChatCompletion("Suggest medical follow-up date and reason. JSON ONLY.", notes);
  }

  @override
  Future<Map<String, dynamic>> summarizeConsultation({
    required String transcriptOrNotes,
    required Map<String, dynamic> patientProfile,
  }) async {
    final prompt = "Patient: ${patientProfile['full_name']}\nNotes: $transcriptOrNotes";
    return _generateChatCompletion("Generate professional SOAP note. JSON ONLY.", prompt);
  }

  Future<Map<String, dynamic>> _generateChatCompletion(String systemPrompt, String userPrompt) async {
    if (_apiKey == null) throw Exception('Grok API Key missing');

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
          'stream': false,
          'temperature': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'];
        return jsonDecode(_extractJson(text));
      }
      throw Exception('Grok Error ${response.statusCode}');
    } catch (e) {
      developer.log('GROK_EXCEPTION: $e', name: 'AiService');
      rethrow;
    }
  }

  String _extractJson(String text) {
    final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
    final match = jsonRegex.firstMatch(text);
    return match?.group(0) ?? text.trim();
  }
}

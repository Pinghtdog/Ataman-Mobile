import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];

  // Using the most stable model name
  static const String _model = 'gemini-1.5-flash';

  static const String triageSystemPrompt = '''
Role: Medical Triage AI (Naga, PH). 
Goal: Assess urgency and routing.
Instructions: Output JSON ONLY. No text before or after.
Schema: {"is_final":bool,"question":"str","options":["str"],"result":{"urgency":"str","case_category":"str","recommended_action":"str","specialty":"str","reason":"str","summary_for_provider":"str"}}
''';

  Future<Map<String, dynamic>> getTriageResponse(String prompt, {int retryCount = 0}) async {
    if (_apiKey == null) throw Exception('API Key missing in .env');

    // Using v1beta for guaranteed JSON mode support
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': "$triageSystemPrompt\n\n$prompt"}]}],
          'generationConfig': {
            'temperature': 0.1,
            'response_mime_type': 'application/json', // Corrected snake_case for REST API
          }
        }),
      );

      developer.log('GEMINI_RESPONSE_STATUS: ${response.statusCode}', name: 'GeminiService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?[0]?['parts']?[0]?['text'];
        if (text == null) throw Exception('AI returned empty content');
        
        developer.log('GEMINI_RESPONSE_RAW: $text', name: 'GeminiService');
        return jsonDecode(_extractJson(text));
      } 
      
      // Handle Rate Limit (429)
      if (response.statusCode == 429 && retryCount < 2) {
        final waitTime = (retryCount + 1) * 5;
        developer.log('GEMINI_429: Retrying in ${waitTime}s...', name: 'GeminiService');
        await Future.delayed(Duration(seconds: waitTime));
        return getTriageResponse(prompt, retryCount: retryCount + 1);
      }

      // If official JSON mode fails, try fallback without the mime_type parameter
      if (response.statusCode == 400) {
        developer.log('GEMINI_400: Config error. Switching to Fallback Mode...', name: 'GeminiService');
        return _getTriageResponseFallback(prompt);
      }

      throw Exception('Gemini Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      developer.log('GEMINI_EXCEPTION: $e', name: 'GeminiService');
      rethrow;
    }
  }

  /// Fallback: Request standard text and manually extract JSON
  Future<Map<String, dynamic>> _getTriageResponseFallback(String prompt) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': "$triageSystemPrompt\n\nIMPORTANT: Output valid JSON ONLY.\n\n$prompt"}]
        }],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?[0]?['parts']?[0]?['text'];
      if (text == null) throw Exception('Fallback failed: No content');
      return jsonDecode(_extractJson(text));
    }
    throw Exception('Triage Service Unavailable. (Status: ${response.statusCode})');
  }

  String _extractJson(String text) {
    final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
    final match = jsonRegex.firstMatch(text);
    if (match != null) {
      return match.group(0)!;
    }
    return text.trim();
  }
}

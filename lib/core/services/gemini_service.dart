import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../constants/app_strings.dart';

class GeminiService {
  final Gemini _gemini = Gemini.instance;

  String _cleanJsonResponse(String text) {
    final RegExp jsonPattern = RegExp(r'\{.*\}', dotAll: true);
    final match = jsonPattern.firstMatch(text);
    
    if (match != null) {
      return match.group(0)!;
    } else {
      throw FormatException("AI did not return valid JSON: $text");
    }
  }

  Future<Map<String, dynamic>> getTriageResponse({
    required String userMessage,
    required String history,
    required int stepCount,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      final String contextBlock = '''
        [DYNAMIC CONTEXT]
        - Current Step: $stepCount of 7. (If Step >= 6, you MUST reach a final decision).
        - Patient Age: \${userProfile?['birth_date'] ?? 'Unknown'}
        - Medical History: \${userProfile?['medical_conditions'] ?? 'None reported'}
        - Patient Language: The user may speak Bicolano, Tagalog, or English.
        
        [CONVERSATION HISTORY]
        $history
        
        [LATEST USER INPUT]
        $userMessage
      ''';

      final response = await _gemini.prompt(parts: [
        Part.text(AppStrings.triageSystemPrompt),
        Part.text(contextBlock),
      ]);

      final responseText = response?.output;
      if (responseText == null) throw Exception('No response from Gemini');

      return jsonDecode(_cleanJsonResponse(responseText));
    } catch (e) {
      rethrow;
    }
  }
}

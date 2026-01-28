import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
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
    // Retry logic for "Too Many Requests" (429)
    int retryCount = 0;
    const int maxRetries = 3; // Increased retries

    while (retryCount <= maxRetries) {
      try {
        final String contextBlock = '''
          [DYNAMIC CONTEXT]
          - Current Step: $stepCount of 7.
          - Patient Age: ${userProfile?['birth_date'] ?? 'Unknown'}
          - Medical History: ${userProfile?['medical_conditions'] ?? 'None reported'}
          
          [CONVERSATION HISTORY]
          $history
          
          [LATEST USER INPUT]
          $userMessage
        ''';

        // Use a faster model if possible, although flutter_gemini 
        // usually defaults to what is configured in Gemini.init or 
        // doesn't expose model per-request easily without a different method.
        // We will focus on prompt efficiency and error handling.
        final response = await _gemini.prompt(parts: [
          Part.text(AppStrings.triageSystemPrompt),
          Part.text(contextBlock),
        ]);

        final responseText = response?.output;
        if (responseText == null) throw Exception('No response from Gemini');

        return jsonDecode(_cleanJsonResponse(responseText));
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        // Handle common rate limiting or overloaded errors
        if (errorStr.contains('429') || 
            errorStr.contains('overloaded') || 
            errorStr.contains('too many requests') ||
            errorStr.contains('resource_exhausted')) {
          
          if (retryCount < maxRetries) {
            retryCount++;
            // Exponential backoff: 1s, 2s, 4s
            final waitTime = Duration(seconds: retryCount * retryCount);
            debugPrint('Gemini Overloaded. Retrying in ${waitTime.inSeconds} seconds...');
            await Future.delayed(waitTime);
            continue; 
          }
        }
        rethrow;
      }
    }
    throw Exception('Gemini is currently overloaded. Please try again in a few moments.');
  }
}

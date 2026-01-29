import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_strings.dart';

class GeminiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  String _cleanJsonResponse(String text) {
    // Remove markdown code blocks if present
    String cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    
    final RegExp jsonPattern = RegExp(r'\{.*\}', dotAll: true);
    final match = jsonPattern.firstMatch(cleaned);
    
    if (match != null) {
      return match.group(0)!;
    } else {
      return jsonEncode({"response": cleaned});
    }
  }

  Future<Map<String, dynamic>> getTriageResponse({
    required String userMessage,
    required String history,
    required int stepCount,
    Map<String, dynamic>? userProfile,
    List<Map<String, dynamic>>? liveFacilities,
  }) async {
    // Convert live facilities to a readable string for the AI
    final facilitiesContext = liveFacilities?.map((f) => 
      "- ${f['name']}: Status: ${f['status']}, Queue: ${f['queue']}, Doctor On-site: ${f['has_doctor']}, Diversion: ${f['is_diversion_active']}"
    ).join('\n') ?? 'No live facility data available.';

    return _callGemini(
      prompt: '''
        ${AppStrings.triageSystemPrompt}
        
        [LIVE SYSTEM CONTEXT - NAGA CITY MEDICAL NETWORK]
        $facilitiesContext
        
        [PATIENT PROFILE]
        - Medical ID: ${userProfile?['medical_id'] ?? 'ATAM-TEMP-99'}
        - Name: ${userProfile?['first_name'] ?? 'Patient'} ${userProfile?['last_name'] ?? ''}
        - History: ${userProfile?['medical_conditions'] ?? 'None reported'}
        
        [CONVERSATION HISTORY]
        $history
        
        [CURRENT INPUT]
        - Step: $stepCount of 7.
        - Message: $userMessage
        
        IMPORTANT: If is_final is true, you MUST include a 'result' object with:
        urgency, case_category, specialty, recommended_action, required_capability, reason, summary_for_provider, and soap_note.
      ''',
      isJsonResponse: true,
    );
  }

  Future<Map<String, dynamic>> summarizeConsultation({
    required String transcriptOrNotes,
    required Map<String, dynamic> patientProfile,
  }) async {
    return _callGemini(
      prompt: '''
        [SYSTEM ROLE]
        You are an expert medical scribe for the ATAMAN Telemedicine system.
        Summarize the consultation into a SOAP note JSON.
        
        [PATIENT]
        - Name: ${patientProfile['full_name']}
        - ID: ${patientProfile['medical_id']}
        
        [INPUT]
        $transcriptOrNotes
        
        [OUTPUT FORMAT]
        {
          "subjective": "...",
          "objective": "...",
          "assessment": "...",
          "plan": "...",
          "summary": "..."
        }
      ''',
      isJsonResponse: true,
    );
  }

  Future<Map<String, dynamic>> _callGemini({
    required String prompt,
    bool isJsonResponse = false,
  }) async {
    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount <= maxRetries) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.2, // Lower temperature for more consistent medical triage
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 2048,
              if (isJsonResponse) 'responseMimeType': 'application/json',
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final String? text = data['candidates']?[0]['content']?[ 'parts']?[0]['text'];
          if (text == null) throw Exception('Empty response from AI');
          
          final cleanedText = _cleanJsonResponse(text);
          return isJsonResponse ? jsonDecode(cleanedText) : {"text": text};
        } else if (response.statusCode == 429) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        } else {
          throw Exception('AI API Error: ${response.statusCode}');
        }
      } catch (e) {
        if (retryCount >= maxRetries) rethrow;
        retryCount++;
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    throw Exception('Failed to connect to AI service');
  }
}

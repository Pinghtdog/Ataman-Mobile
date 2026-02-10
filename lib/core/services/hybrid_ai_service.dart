import 'dart:developer' as developer;
import 'ai_service.dart';
import 'openai_service.dart';
import 'gemini_service.dart';
import 'grok_service.dart';

class HybridAiService implements AiService {
  final OpenAiService _openAi = OpenAiService();
  final GeminiService _gemini = GeminiService();
  final GrokService _grok = GrokService();

  @override
  Future<Map<String, dynamic>> getTriageResponse(String userPrompt) async {
    try {
      return await _openAi.getTriageResponse(userPrompt);
    } catch (e) {
      developer.log('HybridAI: OpenAI failed, trying Gemini...', name: 'AiService');
      try {
        return await _gemini.getTriageResponse(userPrompt);
      } catch (ge) {
        developer.log('HybridAI: Gemini failed, trying Grok...', name: 'AiService');
        try {
          return await _grok.getTriageResponse(userPrompt);
        } catch (groke) {
          developer.log('HybridAI: All AIs failed, entering Interactive Mock Mode.', name: 'AiService');
          return _handleMockTriage(userPrompt);
        }
      }
    }
  }

  /// Interactive Mock Logic that mimics AI flow
  Map<String, dynamic> _handleMockTriage(String prompt) {
    // Count how many "Q:" turns are in the prompt to simulate progress
    final int turnCount = "Q:".allMatches(prompt).length;

    if (turnCount == 0) {
      // Step 1: Initial Question
      return {
        "is_final": false,
        "question": "How long have you been experiencing these symptoms?",
        "options": ["Just today", "2-3 days", "More than a week"],
      };
    } else if (turnCount == 1) {
      // Step 2: Follow-up Question
      return {
        "is_final": false,
        "question": "On a scale of 1-10, how severe is your discomfort?",
        "options": ["1-3 (Mild)", "4-6 (Moderate)", "7-10 (Severe)"],
      };
    } else {
      // Step 3: Final Result based on Red Flags in the whole conversation
      final bool hasUrgentKeywords = prompt.toLowerCase().contains('pain') || 
                                     prompt.toLowerCase().contains('breath') || 
                                     prompt.toLowerCase().contains('blood') ||
                                     prompt.toLowerCase().contains('severe');

      if (hasUrgentKeywords) {
        return {
          "is_final": true,
          "result": {
            "urgency": "URGENT",
            "case_category": "EMERGENCY_SCREENING",
            "recommended_action": "HOSPITAL_ER",
            "required_capability": "HOSPITAL_LEVEL_3",
            "specialty": "Internal Medicine",
            "reason": "Demo Mode: Potential red flags detected (Pain/Breathing/Blood). Proceed to BMC or NCGH.",
            "summary_for_provider": "Interactive Demo: Patient reported symptoms indicating urgency.",
            "is_telemed_suitable": false,
            "ai_confidence": 0.8
          }
        };
      } else {
        return {
          "is_final": true,
          "result": {
            "urgency": "ROUTINE",
            "case_category": "GENERAL_MEDICINE",
            "recommended_action": "HOME_CARE",
            "required_capability": "BHS",
            "specialty": "General Medicine",
            "reason": "Demo Mode: Symptoms appear non-urgent. Local health center monitoring advised.",
            "summary_for_provider": "Interactive Demo: Patient reported mild symptoms.",
            "is_telemed_suitable": true,
            "ai_confidence": 0.9
          }
        };
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getFollowUpRecommendation(String notes) async {
    try {
      return await _openAi.getFollowUpRecommendation(notes);
    } catch (e) {
      try {
        return await _gemini.getFollowUpRecommendation(notes);
      } catch (ge) {
        return {"days_until_follow_up": 7, "reason": "Routine checkup (Demo)"};
      }
    }
  }

  @override
  Future<Map<String, dynamic>> summarizeConsultation({
    required String transcriptOrNotes,
    required Map<String, dynamic> patientProfile,
  }) async {
    try {
      return await _openAi.summarizeConsultation(
        transcriptOrNotes: transcriptOrNotes,
        patientProfile: patientProfile,
      );
    } catch (e) {
      try {
        return await _gemini.summarizeConsultation(
          transcriptOrNotes: transcriptOrNotes,
          patientProfile: patientProfile,
        );
      } catch (ge) {
        return {
          "subjective": transcriptOrNotes,
          "objective": "Recorded via Demo mode.",
          "assessment": "Consultation completed.",
          "plan": "Follow local health guidelines."
        };
      }
    }
  }
}

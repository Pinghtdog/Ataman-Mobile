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

  /// Interactive Mock Logic that mimics AI flow with strict branching
  Map<String, dynamic> _handleMockTriage(String prompt) {
    final String p = prompt.toLowerCase();
    final int turnCount = "Q:".allMatches(prompt).length;

    // --- STEP 0: INITIAL BROAD QUESTION ---
    if (turnCount == 0) {
      return {
        "is_final": false,
        "question": "Ano po ang maitutulong namin sa inyo ngayon? (What is your main concern or reason for triage today?)",
        "options": [
          "May nararamdamang sakit (Pain or Illness)",
          "Para sa Check-up o Konsulta (Routine Check-up)",
          "Maternal / Pagbubuntis (Pregnancy)",
          "Kagat ng Aso o Hayop (Animal Bite)",
          "Emergency / SOS",
          "None of the above / I want to describe it differently"
        ],
      };
    }

    // --- STEP 1: BRANCHED FOLLOW-UP ---
    if (turnCount == 1) {
      if (p.contains('sakit') || p.contains('pain')) {
        return {
          "is_final": false,
          "question": "Saan po banda ang masakit at gaano na ito katagal? (Where is the pain located and how long has it been?)",
          "options": ["Tiyan (Stomach)", "Dibdib (Chest)", "Ulo (Head)", "Iba pa (Others)"],
        };
      } else if (p.contains('maternal') || p.contains('pagbubuntis')) {
        return {
          "is_final": false,
          "question": "Ilang buwan na po ang inyong pagbubuntis? (How many months pregnant are you?)",
          "options": ["1-3 buwan", "4-6 buwan", "7-9 buwan", "Manganganak na (Labor)"],
        };
      } else if (p.contains('bite') || p.contains('kagat')) {
        return {
          "is_final": false,
          "question": "Anong hayop po ang nakakagat sa inyo? (What animal bit you?)",
          "options": ["Aso (Dog)", "Pusa (Cat)", "Iba pa (Others)"],
        };
      } else {
        return {
          "is_final": false,
          "question": "Gaano na po ito katagal? (How long has this been happening?)",
          "options": ["Ngayon lang", "2-3 araw na", "Mahigit isang linggo na"],
        };
      }
    }

    // --- STEP 2: ALIGNED FINAL RESULT ---
    // At this point, we determine the final result based on the primary branch
    
    if (p.contains('bite') || p.contains('kagat')) {
      return {
        "is_final": true,
        "result": {
          "urgency": "URGENT",
          "case_category": "ANIMAL_BITE",
          "recommended_action": "ANIMAL_BITE_CENTER",
          "required_capability": "PRIMARY_CARE",
          "specialty": "Infectious Disease",
          "reason": "Detected Animal Bite. Needs immediate Rabies vaccination at Naga CHO I.",
          "summary_for_provider": "Patient reported an animal bite requiring post-exposure prophylaxis.",
          "is_telemed_suitable": false,
          "ai_confidence": 1.0
        }
      };
    }

    if (p.contains('maternal') || p.contains('pagbubuntis')) {
      return {
        "is_final": true,
        "result": {
          "urgency": "ROUTINE",
          "case_category": "MATERNAL_CARE",
          "recommended_action": "CLINIC_VISIT",
          "required_capability": "PRIMARY_CARE",
          "specialty": "Obstetrics",
          "reason": "Maternal health monitoring. PhilHealth Maternity Package applies at CHO II Lying-in.",
          "summary_for_provider": "Patient seeking pregnancy-related consultation and prenatal care.",
          "is_telemed_suitable": true,
          "ai_confidence": 0.95
        }
      };
    }

    if (p.contains('tiyan') || p.contains('stomach') || p.contains('pain')) {
      // Logic for stomach pain (often related to Appendicitis in our benefits)
      return {
        "is_final": true,
        "result": {
          "urgency": "URGENT",
          "case_category": "GASTROENTEROLOGY",
          "recommended_action": "HOSPITAL_ER",
          "required_capability": "HOSPITAL_LEVEL_2",
          "specialty": "General Surgery",
          "reason": "Severe abdominal pain detected. Potential appendicitis screening at BMC or NCGH.",
          "summary_for_provider": "Patient reported acute stomach pain and discomfort.",
          "is_telemed_suitable": false,
          "ai_confidence": 0.85
        }
      };
    }

    // Default Fallback: General Medicine
    return {
      "is_final": true,
      "result": {
        "urgency": "ROUTINE",
        "case_category": "GENERAL_MEDICINE",
        "recommended_action": "KONSULTA_CHECKUP",
        "required_capability": "PRIMARY_CARE",
        "specialty": "General Medicine",
        "reason": "Non-urgent condition. PhilHealth Konsulta checkup recommended at nearest CHO.",
        "summary_for_provider": "General health consultation for routine symptoms.",
        "is_telemed_suitable": true,
        "ai_confidence": 0.9
      }
    };
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

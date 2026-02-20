import 'dart:developer' as developer;
import 'ai_service.dart';
import 'openai_service.dart';
import 'gemini_service.dart';
import 'groq_service.dart';

class HybridAiService implements AiService {
  final OpenAiService _openAi = OpenAiService();
  final GeminiService _gemini = GeminiService();
  final GroqService _groq = GroqService();

  @override
  Future<Map<String, dynamic>> getTriageResponse(String userPrompt) async {
    // Directly using Groq for triage as requested.
    try {
      return await _groq.getTriageResponse(userPrompt);
    } catch (e) {
      developer.log('HybridAI: Groq failed, entering Interactive Mock Mode.', name: 'AiService');
      return _handleMockTriage(userPrompt);
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
        "input_type": "BUTTONS",
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
          "input_type": "BUTTONS",
          "question": "Saan po banda ang masakit at gaano na ito katagal? (Where is the pain located and how long has it been?)",
          "options": ["Tiyan (Stomach)", "Dibdib (Chest)", "Ulo (Head)", "Iba pa (Others)", "None of the above / I want to describe it differently"],
        };
      } else if (p.contains('maternal') || p.contains('pagbubuntis')) {
        return {
          "is_final": false,
          "input_type": "BUTTONS",
          "question": "Ilang buwan na po ang inyong pagbubuntis? (How many months pregnant are you?)",
          "options": ["1-3 buwan", "4-6 buwan", "7-9 buwan", "Manganganak na (Labor)", "None of the above / I want to describe it differently"],
        };
      } else if (p.contains('bite') || p.contains('kagat')) {
        return {
          "is_final": false,
          "input_type": "BUTTONS",
          "question": "Anong hayop po ang nakakagat sa inyo? (What animal bit you?)",
          "options": ["Aso (Dog)", "Pusa (Cat)", "Iba pa (Others)", "None of the above / I want to describe it differently"],
        };
      } else {
        return {
          "is_final": false,
          "input_type": "TEXT",
          "question": "Maaari niyo po bang ilarawan nang mas detalyado ang inyong nararamdaman? (Could you describe what you're feeling in more detail?)",
          "options": ["None of the above / I want to describe it differently"],
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
          "ai_confidence": 1.0,
          "soap_note": {
            "subjective": "Patient reports animal bite.",
            "objective": "No physical exam performed.",
            "assessment": "Potential rabies exposure.",
            "plan": "Immediate referral to Animal Bite Center for PEP."
          }
        }
      };
    }

    if (p.contains('maternal') || p.contains('pagbubuntis')) {
      return {
        "is_final": true,
        "result": {
          "urgency": "ROUTINE",
          "case_category": "MATERNAL_CARE",
          "recommended_action": "BHC_APPOINTMENT",
          "required_capability": "BARANGAY_HEALTH_STATION",
          "specialty": "Obstetrics",
          "reason": "Maternal health monitoring. PhilHealth Maternity Package applies at CHO II Lying-in.",
          "summary_for_provider": "Patient seeking pregnancy-related consultation and prenatal care.",
          "is_telemed_suitable": true,
          "ai_confidence": 0.95,
          "soap_note": {
            "subjective": "Patient seeking prenatal care.",
            "objective": "Gestational age noted.",
            "assessment": "Routine pregnancy monitoring.",
            "plan": "Schedule BHC appointment and prenatal labs."
          }
        }
      };
    }

    if (p.contains('tiyan') || p.contains('stomach') || p.contains('pain')) {
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
          "ai_confidence": 0.85,
          "soap_note": {
            "subjective": "Acute abdominal pain.",
            "objective": "Pain localized to right lower quadrant.",
            "assessment": "Possible appendicitis.",
            "plan": "Immediate referral to ER for surgical evaluation."
          }
        }
      };
    }

    // Default Fallback: General Medicine
    return {
      "is_final": true,
      "result": {
        "urgency": "ROUTINE",
        "case_category": "GENERAL_MEDICINE",
        "recommended_action": "BHC_APPOINTMENT",
        "required_capability": "BARANGAY_HEALTH_STATION",
        "specialty": "General Medicine",
        "reason": "Non-urgent condition. PhilHealth Konsulta checkup recommended at nearest CHO.",
        "summary_for_provider": "General health consultation for routine symptoms.",
        "is_telemed_suitable": true,
        "ai_confidence": 0.9,
        "soap_note": {
          "subjective": "General health concerns.",
          "objective": "Vitals stable.",
          "assessment": "Routine medical issue.",
          "plan": "Advised follow up at local health center."
        }
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
        try {
          return await _groq.getFollowUpRecommendation(notes);
        } catch (groqe) {
          return {"days_until_follow_up": 7, "reason": "Routine checkup (Demo)"};
        }
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
        try {
          return await _groq.summarizeConsultation(
            transcriptOrNotes: transcriptOrNotes,
            patientProfile: patientProfile,
          );
        } catch (groqe) {
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
}

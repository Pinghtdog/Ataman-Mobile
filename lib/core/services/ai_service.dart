abstract class AiService {
  Future<Map<String, dynamic>> getTriageResponse(String userPrompt);
  Future<Map<String, dynamic>> getFollowUpRecommendation(String notes);
  Future<Map<String, dynamic>> summarizeConsultation({
    required String transcriptOrNotes,
    required Map<String, dynamic> patientProfile,
  });
}
 
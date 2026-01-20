import '../models/triage_model.dart';
import '../services/triage_service.dart';

class TriageRepository {
  final TriageService _triageService;

  TriageRepository(this._triageService);

  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    try {
      return await _triageService.getNextStep(history);
    } catch (e) {
      rethrow;
    }
  }

  Future<TriageResult> performTriage(String symptoms) async {
    try {
      return await _triageService.classifySymptoms(symptoms);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TriageResult>> getHistory() async {
    try {
      return await _triageService.getTriageHistory();
    } catch (e) {
      rethrow;
    }
  }
}

import '../../data/models/triage_model.dart';

abstract class ITriageRepository {
  Future<void> initializeSession();
  Future<TriageStep> getNextStep(List<Map<String, String>> history);
  Future<TriageResult> performTriage(String symptoms);
  Future<List<TriageResult>> getHistory();
}

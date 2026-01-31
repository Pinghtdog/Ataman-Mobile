import '../../../../core/data/repositories/base_repository.dart';
import '../../domain/repositories/i_triage_repository.dart';
import '../models/triage_model.dart';
import '../services/triage_service.dart';

class TriageRepository extends BaseRepository implements ITriageRepository {
  final TriageService _triageService;

  TriageRepository(this._triageService);

  @override
  Future<void> initializeSession() async {
    await safeCall(() => _triageService.initializeSession());
  }

  @override
  Future<TriageStep> getNextStep(List<Map<String, String>> history) async {
    return await safeCall(() => _triageService.getNextStep(history));
  }

  @override
  Future<TriageResult> performTriage(String symptoms) async {
    return await safeCall(() => _triageService.performTriage(symptoms));
  }

  @override
  Future<List<TriageResult>> getHistory() async {
    return await safeCall(() => _triageService.getTriageHistory());
  }
}

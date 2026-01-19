import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/triage_model.dart';
import '../../data/repositories/triage_repository.dart';
import 'triage_state.dart';

class TriageCubit extends Cubit<TriageState> {
  final TriageRepository _triageRepository;

  TriageCubit({required TriageRepository triageRepository})
      : _triageRepository = triageRepository,
        super(TriageInitial());

  List<Map<String, String>> _history = [];

  Future<void> startTriage() async {
    _history = [];
    emit(TriageLoading());
    try {
      final step = await _triageRepository.getNextStep(_history);
      emit(TriageStepLoaded(step, history: List.from(_history)));
    } catch (e) {
      emit(TriageError(e.toString()));
    }
  }

  Future<void> selectOption(String question, String answer) async {
    _history.add({'question': question, 'answer': answer});
    await _processNextStep();
  }

  // New method to retry the current state of history without adding new answers
  Future<void> retryLastStep() async {
    await _processNextStep();
  }

  Future<void> _processNextStep() async {
    emit(TriageLoading());
    try {
      final step = await _triageRepository.getNextStep(_history);
      if (step.isFinal && step.result != null) {
        emit(TriageSuccess(step.result!));
      } else {
        emit(TriageStepLoaded(step, history: List.from(_history)));
      }
    } catch (e) {
      emit(TriageError(e.toString()));
    }
  }

  Future<void> performTriage(String symptoms) async {
    if (symptoms.trim().isEmpty) {
      emit(const TriageError("Please describe your symptoms"));
      return;
    }

    emit(TriageLoading());
    try {
      final result = await _triageRepository.performTriage(symptoms);
      emit(TriageSuccess(result));
    } catch (e) {
      emit(TriageError(e.toString()));
    }
  }

  void reset() {
    _history = [];
    emit(TriageInitial());
  }
}

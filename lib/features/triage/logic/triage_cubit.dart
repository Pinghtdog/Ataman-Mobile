// lib/features/triage/logic/triage_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../domain/repositories/i_triage_repository.dart';
import 'triage_state.dart';

class TriageCubit extends Cubit<TriageState> {
  final ITriageRepository _triageRepository;

  TriageCubit({required ITriageRepository triageRepository})
      : _triageRepository = triageRepository,
        super(TriageInitial());

  List<Map<String, String>> _history = [];

  Future<void> startTriage() async {
    _history = [];
    _fetchNextStep();
  }

  Future<void> selectOption(String question, String answer) async {
    _history.add({'question': question, 'answer': answer});
    _fetchNextStep();
  }

  Future<void> retryLastStep() async => _fetchNextStep();

  Future<void> _fetchNextStep() async {
    emit(TriageLoading());
    try {
      final step = await _triageRepository.getNextStep(_history);

      if (step.isFinal && step.result != null) {
        emit(TriageSuccess(step.result!));
      } else {
        emit(TriageStepLoaded(step, history: List.from(_history)));
      }
    } catch (e) {
      // Mapping raw errors to user-friendly messages via our Failures system
      final String message = e is Failure ? e.message : e.toString();
      emit(TriageError(message));
    }
  }

  void reset() {
    _history = [];
    emit(TriageInitial());
  }
}
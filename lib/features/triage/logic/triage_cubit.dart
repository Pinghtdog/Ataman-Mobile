import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../domain/repositories/i_triage_repository.dart';
import 'triage_state.dart';

/// [TriageCubit] manages the state and business logic of a Smart Triage session.
///
/// It acts as a bridge between the UI and the [ITriageRepository], handling
/// session initialization, step-by-step navigation, and final result processing.
///
/// **Session Flow:**
/// 1. [startTriage] initializes the AI context and fetches the first question.
/// 2. [selectOption] records user responses and triggers the next AI-driven step.
/// 3. [TriageSuccess] is emitted when the AI determines a final medical assessment.
class TriageCubit extends Cubit<TriageState> {
  final ITriageRepository _triageRepository;

  TriageCubit({required ITriageRepository triageRepository})
      : _triageRepository = triageRepository,
        super(TriageInitial());

  /// Internal storage for the conversation history between the user and the AI.
  /// Format: `[{'question': '...', 'answer': '...'}]`
  List<Map<String, String>> _history = [];

  /// Initiates a new triage session.
  ///
  /// This method clears previous history and calls the repository to initialize
  /// the backend session with the user's medical profile context.
  Future<void> startTriage() async {
    if (state is TriageLoading) return; // Prevent double-start
    
    emit(TriageLoading());
    try {
      _history = [];
      // Initialize profile context ONCE at the start
      await _triageRepository.initializeSession();
      
      await _fetchNextStep();
    } catch (e) {
      final String message = e is Failure ? e.message : e.toString();
      emit(TriageError(message));
    }
  }

  /// Processes the user's selection and requests the next step.
  ///
  /// Appends the [question] and [answer] to the session history and 
  /// triggers [_fetchNextStep] to get the AI's response.
  Future<void> selectOption(String question, String answer) async {
    if (state is TriageLoading) return; // IGNORE CLICKS WHILE LOADING

    _history.add({'question': question, 'answer': answer});
    await _fetchNextStep();
  }

  /// Attempts to recover from an error state.
  ///
  /// If the error happened at the start, it restarts the triage.
  /// Otherwise, it re-fetches the next step based on the existing history.
  Future<void> retryLastStep() async {
    if (state is TriageLoading) return;
    if (state is! TriageError) return;

    if (_history.isEmpty) {
      await startTriage();
    } else {
      await _fetchNextStep();
    }
  }

  /// Core logic for communicating with the AI backend.
  ///
  /// Fetches the next [TriageStep] from the repository. If the step is final,
  /// it emits [TriageSuccess] with the result; otherwise, it emits [TriageStepLoaded].
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
      final String message = e is Failure ? e.message : e.toString();
      emit(TriageError(message));
    }
  }

  /// Resets the cubit to its initial state and clears the history.
  void reset() {
    _history = [];
    emit(TriageInitial());
  }
}

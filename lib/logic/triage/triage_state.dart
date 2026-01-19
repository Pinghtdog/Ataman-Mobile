import 'package:equatable/equatable.dart';
import '../../data/models/triage_model.dart';

abstract class TriageState extends Equatable {
  const TriageState();

  @override
  List<Object?> get props => [];
}

class TriageInitial extends TriageState {}

class TriageLoading extends TriageState {}

class TriageStepLoaded extends TriageState {
  final TriageStep step;
  final List<Map<String, String>> history;

  const TriageStepLoaded(this.step, {this.history = const []});

  @override
  List<Object?> get props => [step, history];
}

class TriageSuccess extends TriageState {
  final TriageResult result;
  const TriageSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class TriageHistoryLoaded extends TriageState {
  final List<TriageResult> history;
  const TriageHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class TriageError extends TriageState {
  final String message;
  final List<Map<String, String>> history;

  const TriageError(this.message, {this.history = const []});

  @override
  List<Object?> get props => [message, history];
}

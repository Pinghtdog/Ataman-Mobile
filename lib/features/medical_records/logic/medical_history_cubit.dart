import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/medical_history_model.dart';
import '../data/repositories/medical_history_repository.dart';

/// Base state for medical history operations.
abstract class MedicalHistoryState extends Equatable {
  const MedicalHistoryState();
  @override
  List<Object?> get props => [];
}

/// Initial state of the medical history module.
class MedicalHistoryInitial extends MedicalHistoryState {}

/// State emitted while fetching medical history data.
class MedicalHistoryLoading extends MedicalHistoryState {}

/// State emitted when medical history has been successfully loaded.
class MedicalHistoryLoaded extends MedicalHistoryState {
  /// The list of medical history items for the user.
  final List<MedicalHistoryItem> history;
  
  const MedicalHistoryLoaded(this.history);
  
  @override
  List<Object?> get props => [history];
}

/// State emitted when an error occurs during medical history operations.
class MedicalHistoryError extends MedicalHistoryState {
  /// The error message.
  final String message;
  
  const MedicalHistoryError(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// [MedicalHistoryCubit] manages the state and business logic for the user's medical timeline.
///
/// It coordinates with the [MedicalHistoryRepository] to:
/// 1. **Retrieve History**: Fetch a chronological list of medical events and uploaded documents.
/// 2. **Manage Records**: Add new entries to the medical history (e.g., manual document uploads).
class MedicalHistoryCubit extends Cubit<MedicalHistoryState> {
  final MedicalHistoryRepository _repository;

  MedicalHistoryCubit(this._repository) : super(MedicalHistoryInitial());

  /// Fetches the complete medical history for a specific [userId].
  ///
  /// Emits [MedicalHistoryLoading] during the request and [MedicalHistoryLoaded] 
  /// upon successful retrieval. In case of failure, it emits [MedicalHistoryError].
  Future<void> fetchHistory(String userId) async {
    emit(MedicalHistoryLoading());
    try {
      final history = await _repository.getMedicalHistory(userId);
      emit(MedicalHistoryLoaded(history));
    } catch (e) {
      emit(MedicalHistoryError(e.toString()));
    }
  }

  /// Adds a new [item] to the user's medical history record.
  ///
  /// After successfully adding the item, it automatically triggers a 
  /// refresh of the entire history list by calling [fetchHistory].
  Future<void> addHistoryItem(MedicalHistoryItem item, String userId) async {
    try {
      await _repository.addMedicalHistory(item, userId);
      await fetchHistory(userId);
    } catch (e) {
      emit(MedicalHistoryError(e.toString()));
    }
  }
}

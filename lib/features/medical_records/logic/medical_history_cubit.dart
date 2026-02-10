import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/medical_history_model.dart';
import '../data/repositories/medical_history_repository.dart';

abstract class MedicalHistoryState extends Equatable {
  const MedicalHistoryState();
  @override
  List<Object?> get props => [];
}

class MedicalHistoryInitial extends MedicalHistoryState {}
class MedicalHistoryLoading extends MedicalHistoryState {}
class MedicalHistoryLoaded extends MedicalHistoryState {
  final List<MedicalHistoryItem> history;
  const MedicalHistoryLoaded(this.history);
  @override
  List<Object?> get props => [history];
}
class MedicalHistoryError extends MedicalHistoryState {
  final String message;
  const MedicalHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class MedicalHistoryCubit extends Cubit<MedicalHistoryState> {
  final MedicalHistoryRepository _repository;

  MedicalHistoryCubit(this._repository) : super(MedicalHistoryInitial());

  Future<void> fetchHistory(String userId) async {
    emit(MedicalHistoryLoading());
    try {
      final history = await _repository.getMedicalHistory(userId);
      emit(MedicalHistoryLoaded(history));
    } catch (e) {
      emit(MedicalHistoryError(e.toString()));
    }
  }

  Future<void> addHistoryItem(MedicalHistoryItem item, String userId) async {
    try {
      await _repository.addMedicalHistory(item, userId);
      await fetchHistory(userId);
    } catch (e) {
      emit(MedicalHistoryError(e.toString()));
    }
  }
}

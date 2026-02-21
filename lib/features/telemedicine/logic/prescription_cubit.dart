import 'dart:async';
import 'package:ataman/features/telemedicine/logic/prescription_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../medical_records/data/repositories/prescription_repository.dart';

/// [PrescriptionCubit] manages the state and real-time synchronization of medical prescriptions.
///
/// **Responsibilities:**
/// 1. **Real-time Synchronization**: Subscribes to updates from the [PrescriptionRepository] 
///    to reflect changes in the user's prescription list immediately.
/// 2. **State Management**: Emits [PrescriptionLoading], [PrescriptionLoaded], 
///    and [PrescriptionError] states to handle UI rendering across different lifecycle stages.
class PrescriptionCubit extends Cubit<PrescriptionState> {
  final PrescriptionRepository _prescriptionRepository;
  StreamSubscription? _prescriptionSubscription;

  PrescriptionCubit({required PrescriptionRepository prescriptionRepository})
      : _prescriptionRepository = prescriptionRepository,
        super(PrescriptionInitial());

  /// Establishes a real-time connection to the user's prescription records.
  /// 
  /// Cancels any existing subscription before starting a new one for the given [userId].
  /// On successful data retrieval, it emits [PrescriptionLoaded].
  /// On error, it emits [PrescriptionError] with the relevant message.
  void startWatchingPrescriptions(String userId) {
    emit(PrescriptionLoading());
    _prescriptionSubscription?.cancel();
    _prescriptionSubscription = _prescriptionRepository.watchUserPrescriptions(userId).listen(
      (prescriptions) {
        emit(PrescriptionLoaded(prescriptions));
      },
      onError: (error) {
        emit(PrescriptionError(error.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _prescriptionSubscription?.cancel();
    return super.close();
  }
}

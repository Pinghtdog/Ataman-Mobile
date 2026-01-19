import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/prescription_repository.dart';
import 'prescription_state.dart';

class PrescriptionCubit extends Cubit<PrescriptionState> {
  final PrescriptionRepository _prescriptionRepository;
  StreamSubscription? _prescriptionSubscription;

  PrescriptionCubit({required PrescriptionRepository prescriptionRepository})
      : _prescriptionRepository = prescriptionRepository,
        super(PrescriptionInitial());

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

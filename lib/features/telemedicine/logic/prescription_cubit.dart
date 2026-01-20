import 'dart:async';
import 'package:ataman/features/telemedicine/logic/prescription_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../medical_records/data/repositories/prescription_repository.dart';

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

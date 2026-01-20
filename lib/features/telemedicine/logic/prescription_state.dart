import 'package:equatable/equatable.dart';

import '../../medical_records/data/models/prescription_model.dart';

abstract class PrescriptionState extends Equatable {
  const PrescriptionState();

  @override
  List<Object?> get props => [];
}

class PrescriptionInitial extends PrescriptionState {}

class PrescriptionLoading extends PrescriptionState {}

class PrescriptionLoaded extends PrescriptionState {
  final List<Prescription> prescriptions;
  const PrescriptionLoaded(this.prescriptions);

  @override
  List<Object?> get props => [prescriptions];
}

class PrescriptionError extends PrescriptionState {
  final String message;
  const PrescriptionError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../data/models/facility_model.dart';

abstract class FacilityState extends Equatable {
  const FacilityState();

  @override
  List<Object?> get props => [];
}

class FacilityInitial extends FacilityState {}

class FacilityLoading extends FacilityState {}

class FacilityLoaded extends FacilityState {
  final List<Facility> facilities;
  const FacilityLoaded(this.facilities);

  @override
  List<Object?> get props => [facilities];
}

class FacilityError extends FacilityState {
  final String message;
  const FacilityError(this.message);

  @override
  List<Object?> get props => [message];
}

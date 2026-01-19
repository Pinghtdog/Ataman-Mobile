import 'package:equatable/equatable.dart';
import '../../data/models/emergency_request_model.dart';

abstract class EmergencyState extends Equatable {
  const EmergencyState();

  @override
  List<Object?> get props => [];
}

class EmergencyInitial extends EmergencyState {}

class EmergencyLoading extends EmergencyState {}

class EmergencyActive extends EmergencyState {
  final EmergencyRequest request;
  const EmergencyActive(this.request);

  @override
  List<Object?> get props => [request];
}

class EmergencySuccess extends EmergencyState {}

class EmergencyError extends EmergencyState {
  final String message;
  const EmergencyError(this.message);

  @override
  List<Object?> get props => [message];
}

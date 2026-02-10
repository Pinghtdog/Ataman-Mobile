import 'package:equatable/equatable.dart';
import '../data/models/ambulance_model.dart';
import '../data/models/emergency_request_model.dart';

abstract class EmergencyState extends Equatable {
  const EmergencyState();

  @override
  List<Object?> get props => [];
}

class EmergencyInitial extends EmergencyState {}

class EmergencyLoading extends EmergencyState {}

class EmergencyActive extends EmergencyState {
  final EmergencyRequest request;
  final Ambulance? ambulance;

  const EmergencyActive(this.request, {this.ambulance});

  @override
  List<Object?> get props => [request, ambulance];

  EmergencyActive copyWith({
    EmergencyRequest? request,
    Ambulance? ambulance,
  }) {
    return EmergencyActive(
      request ?? this.request,
      ambulance: ambulance ?? this.ambulance,
    );
  }
}

class EmergencySuccess extends EmergencyState {}

class EmergencyQueued extends EmergencyState {
  final Map<String, dynamic> queuedData;
  const EmergencyQueued(this.queuedData);

  @override
  List<Object?> get props => [queuedData];
}

class EmergencyError extends EmergencyState {
  final String message;
  const EmergencyError(this.message);

  @override
  List<Object?> get props => [message];
}

part of 'health_alerts_cubit.dart';

abstract class HealthAlertsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HealthAlertsInitial extends HealthAlertsState {}

class HealthAlertsLoading extends HealthAlertsState {}

class HealthAlertsLoaded extends HealthAlertsState {
  final List<Map<String, dynamic>> alerts;
  final String currentCategory;

  HealthAlertsLoaded(this.alerts, this.currentCategory);

  @override
  List<Object?> get props => [alerts, currentCategory];
}

class HealthAlertsError extends HealthAlertsState {
  final String message;

  HealthAlertsError(this.message);

  @override
  List<Object?> get props => [message];
}

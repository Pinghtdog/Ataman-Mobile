part of 'telemedicine_cubit.dart';

abstract class TelemedicineState extends Equatable {
  const TelemedicineState();

  @override
  List<Object?> get props => [];
}

class TelemedicineInitial extends TelemedicineState {}

class TelemedicineLoading extends TelemedicineState {}

class TelemedicineLoaded extends TelemedicineState {
  final List<DoctorModel> doctors;
  final List<TelemedicineService> services;
  final List<String> symptoms;

  const TelemedicineLoaded(
    this.doctors, {
    this.services = const [],
    this.symptoms = const [],
  });

  TelemedicineLoaded copyWith({
    List<DoctorModel>? doctors,
    List<TelemedicineService>? services,
    List<String>? symptoms,
  }) {
    return TelemedicineLoaded(
      doctors ?? this.doctors,
      services: services ?? this.services,
      symptoms: symptoms ?? this.symptoms,
    );
  }

  @override
  List<Object?> get props => [doctors, services, symptoms];
}

class TelemedicineError extends TelemedicineState {
  final String message;

  const TelemedicineError(this.message);

  @override
  List<Object?> get props => [message];
}

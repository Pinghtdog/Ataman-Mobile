part of 'family_cubit.dart';

abstract class FamilyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyLoaded extends FamilyState {
  final List<FamilyMember> members;

  FamilyLoaded(this.members);

  @override
  List<Object?> get props => [members];
}

class FamilyError extends FamilyState {
  final String message;

  FamilyError(this.message);

  @override
  List<Object?> get props => [message];
}

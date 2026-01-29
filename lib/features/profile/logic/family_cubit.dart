import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/model/family_member_model.dart';
import '../data/repositories/family_repository.dart';

part 'family_state.dart';

class FamilyCubit extends Cubit<FamilyState> {
  final FamilyRepository _repository;

  FamilyCubit(this._repository) : super(FamilyInitial());

  Future<void> loadFamilyMembers(String userId) async {
    emit(FamilyLoading());
    try {
      final members = await _repository.getFamilyMembers(userId);
      emit(FamilyLoaded(members));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  Future<void> addFamilyMember(FamilyMember member) async {
    try {
      await _repository.addFamilyMember(member);
      loadFamilyMembers(member.userId);
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  Future<void> deleteFamilyMember(String memberId, String userId) async {
    final currentState = state;
    if (currentState is FamilyLoaded) {
      // Optimistic UI update
      final updatedMembers = currentState.members.where((m) => m.id != memberId).toList();
      emit(FamilyLoaded(updatedMembers));
      
      try {
        await _repository.deleteFamilyMember(memberId);
      } catch (e) {
        // Rollback on error
        loadFamilyMembers(userId);
        emit(FamilyError(e.toString()));
      }
    }
  }
}

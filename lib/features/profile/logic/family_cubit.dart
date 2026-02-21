import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/model/family_member_model.dart';
import '../data/repositories/family_repository.dart';

part 'family_state.dart';

/// [FamilyCubit] manages the state and business logic for family member management.
///
/// It handles fetching, adding, and deleting family members (dependents) 
/// associated with the main user account.
///
/// **Key Responsibilities:**
/// 1. **Data Loading**: Retrieves the list of family members for a specific user.
/// 2. **Member Enrollment**: Facilitates adding new family members to the user's profile.
/// 3. **Member Removal**: Handles the deletion of family members with optimistic UI updates.
class FamilyCubit extends Cubit<FamilyState> {
  final FamilyRepository _repository;

  FamilyCubit(this._repository) : super(FamilyInitial());

  /// Loads all family members associated with the given [userId].
  /// 
  /// Emits [FamilyLoading] while fetching and [FamilyLoaded] upon success.
  /// If the fetch fails, it emits [FamilyError] with the relevant error message.
  Future<void> loadFamilyMembers(String userId) async {
    emit(FamilyLoading());
    try {
      final members = await _repository.getFamilyMembers(userId);
      emit(FamilyLoaded(members));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  /// Adds a new [member] to the user's family list.
  /// 
  /// After a successful addition, it automatically refreshes the member list
  /// by calling [loadFamilyMembers].
  Future<void> addFamilyMember(FamilyMember member) async {
    try {
      await _repository.addFamilyMember(member);
      loadFamilyMembers(member.userId);
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  /// Removes a family member identified by [memberId].
  /// 
  /// **Optimistic UI Update**:
  /// To provide a smooth user experience, this method immediately emits an updated 
  /// [FamilyLoaded] state excluding the target member before the network request completes.
  /// 
  /// If the deletion fails on the backend, it triggers a rollback by re-fetching 
  /// the data using [loadFamilyMembers] and emitting a [FamilyError].
  Future<void> deleteFamilyMember(String memberId, String userId) async {
    final currentState = state;
    if (currentState is FamilyLoaded) {
      // Optimistic UI update: Remove from list immediately
      final updatedMembers = currentState.members.where((m) => m.id != memberId).toList();
      emit(FamilyLoaded(updatedMembers));
      
      try {
        await _repository.deleteFamilyMember(memberId);
      } catch (e) {
        // Rollback on error: Refresh from server and show error
        loadFamilyMembers(userId);
        emit(FamilyError(e.toString()));
      }
    }
  }
}

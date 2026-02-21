import 'package:ataman/features/profile/logic/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/domain/repositories/i_user_repository.dart';

/// [ProfileCubit] manages the user's profile information and synchronization.
///
/// It handles:
/// 1. **Data Retrieval**: Fetching the user's detailed profile from the [IUserRepository].
/// 2. **Profile Updates**: Persisting changes made to the user's identity, contact, or medical information.
///
/// This cubit emits [ProfileLoading], [ProfileSuccess], and [ProfileError] states
/// to reflect the current status of profile operations.
class ProfileCubit extends Cubit<ProfileState> {
  final IUserRepository _userRepository;

  ProfileCubit({required IUserRepository userRepository})
      : _userRepository = userRepository,
        super(ProfileInitial());

  /// Updates the [user] profile in the persistent storage.
  /// 
  /// Emits [ProfileLoading] during the update process and [ProfileSuccess] upon completion.
  /// If the update fails, it emits [ProfileError] with the failure reason.
  Future<void> updateProfile(UserModel user) async {
    emit(ProfileLoading());
    try {
      await _userRepository.updateProfile(user);
      emit(ProfileSuccess(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// Fetches the profile data for the specified [userId].
  /// 
  /// Emits [ProfileLoading] while fetching. If the user is found, it emits [ProfileSuccess];
  /// otherwise, it emits [ProfileError].
  Future<void> loadProfile(String userId) async {
    emit(ProfileLoading());
    try {
      final user = await _userRepository.getUserProfile(userId);
      if (user != null) {
        emit(ProfileSuccess(user));
      } else {
        emit(const ProfileError("User not found"));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}

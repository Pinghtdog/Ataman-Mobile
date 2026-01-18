import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _userRepository;

  ProfileCubit({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(ProfileInitial());

  Future<void> updateProfile(UserModel user) async {
    emit(ProfileLoading());
    try {
      await _userRepository.updateProfile(user);
      emit(ProfileSuccess(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

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

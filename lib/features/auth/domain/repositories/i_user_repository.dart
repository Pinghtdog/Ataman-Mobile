
import '../../data/models/user_model.dart';

abstract class IUserRepository {
  Future<UserModel?> getUserProfile(String userId);
  Future<void> updateFCMToken(String userId, String token);
  Future<void> updateProfile(UserModel user);
}

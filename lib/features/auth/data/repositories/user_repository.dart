import '../../../../core/data/repositories/base_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../models/user_model.dart';

class UserRepository extends BaseRepository implements IUserRepository {
  
  @override
  Future<UserModel?> getUserProfile(String userId) async {
    return await getCached<UserModel?>(
      'user_profile_$userId',
      () async {
        final data = await safeCall(() => supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single());
        
        return UserModel.fromMap(data);
      },
      ttl: const Duration(minutes: 15),
    );
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    await safeCall(() => supabase
        .from('users')
        .upsert(user.toMap()));
    
    cache.invalidate('user_profile_${user.id}');
  }

  @override
  Future<void> updateFCMToken(String userId, String token) async {
    await safeCall(() => supabase
        .from('users')
        .update({'fcm_token': token})
        .eq('id', userId));
  }
}

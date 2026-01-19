import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  
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
      ttl: const Duration(minutes: 15), // Profile can be cached longer
    );
  }

  Future<void> updateProfile(UserModel user) async {
    await safeCall(() => supabase
        .from('users')
        .upsert(user.toMap()));
    
    // Invalidate cache after update
    cache.invalidate('user_profile_${user.id}');
  }

  Future<void> updateFCMToken(String userId, String token) async {
    await safeCall(() => supabase
        .from('users')
        .update({'fcm_token': token})
        .eq('id', userId));
  }
}

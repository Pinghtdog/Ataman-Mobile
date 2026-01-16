import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Get User Profile from 'users' table
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      return UserModel.fromMap(data);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update User Profile
  Future<void> updateProfile(UserModel user) async {
    try {
      await _supabase
          .from('users')
          .upsert(user.toMap());
    } catch (e) {
      throw Exception('Update User Failed: $e');
    }
  }

  // Update FCM Token
  Future<void> updateFCMToken(String userId, String token) async {
    try {
      await _supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}

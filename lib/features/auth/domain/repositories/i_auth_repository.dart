import 'package:supabase_flutter/supabase_flutter.dart';

abstract class IAuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
  
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  });

  Future<AuthResponse> signIn({
    String? email,
    String? phone,
    required String password,
  });

  Future<void> signOut();
}

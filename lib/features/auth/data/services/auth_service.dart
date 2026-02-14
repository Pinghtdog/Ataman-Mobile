import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    String? email,
    String? phone,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'https://lambent-tarsier-6e738f.netlify.app/',
      data: {
        'full_name': fullName,
        if (phoneNumber != null) 'phone': phoneNumber,
        ...?additionalData,
      },
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

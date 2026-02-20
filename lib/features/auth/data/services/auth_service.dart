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
    required String firstName,
    required String lastName,
    String? middleName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'https://benevolent-muffin-aeafa7.netlify.app/',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        if (middleName != null) 'middle_name': middleName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        ...?additionalData,
      },
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

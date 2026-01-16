import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  // Stream session changes (returns Supabase's AuthState)
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => _authService.currentUser;

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    return await _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
      additionalData: additionalData,
    );
  }

  // Sign In (Supports Email or Phone)
  Future<AuthResponse> signIn({
    String? email,
    String? phone,
    required String password,
  }) async {
    return await _authService.signIn(
      email: email,
      phone: phone,
      password: password,
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _authService.signOut();
  }
}

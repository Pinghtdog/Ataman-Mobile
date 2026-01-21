import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/base_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepository extends BaseRepository implements IAuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  @override
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  @override
  User? get currentUser => _authService.currentUser;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    return await safeCall(() => _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
      additionalData: additionalData,
    ));
  }

  @override
  Future<AuthResponse> signIn({
    String? email,
    String? phone,
    required String password,
  }) async {
    return await safeCall(() => _authService.signIn(
      email: email,
      phone: phone,
      password: password,
    ));
  }

  @override
  Future<void> signOut() async {
    await safeCall(() => _authService.signOut());
  }
}

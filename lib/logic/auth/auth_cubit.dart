import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final sb.User user;
  final UserModel? profile;

  Authenticated(this.user, {this.profile});

  @override
  List<Object?> get props => [user, profile];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  StreamSubscription<sb.AuthState>? _authStateSubscription;

  AuthCubit({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        super(AuthInitial()) {
    _init();
  }

  void _init() {
    _authStateSubscription = _authRepository.authStateChanges.listen((data) async {
      final sb.User? user = data.session?.user;
      
      if (user != null) {
        if (state is! Authenticated) {
          final profile = await _userRepository.getUserProfile(user.id);
          emit(Authenticated(user, profile: profile));
        }
      } else {
        if (state is! AuthLoading) {
          emit(Unauthenticated());
        }
      }
    });
  }

  Future<void> login(String identity, String password, {bool isPhoneLogin = false}) async {
    emit(AuthLoading());
    try {
      debugPrint('Attempting login for: $identity (isPhone: $isPhoneLogin)');
      final response = await _authRepository.signIn(
        email: isPhoneLogin ? null : identity,
        phone: isPhoneLogin ? identity : null,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('Login success for user: ${response.user!.id}');
        final profile = await _userRepository.getUserProfile(response.user!.id);
        emit(Authenticated(response.user!, profile: profile));
      } else {
        emit(AuthError("Login failed: User not found."));
        emit(Unauthenticated());
      }
    } catch (e) {
      debugPrint('Login error: $e');
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(Unauthenticated());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? birthDate,
    String? barangay,
    String? philhealthId,
  }) async {
    emit(AuthLoading());
    try {
      String? formattedDate = birthDate;
      if (birthDate != null && birthDate.contains('/')) {
        final parts = birthDate.split('/').map((e) => e.trim()).toList();
        if (parts.length == 3) {
          formattedDate = "${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}";
        }
      }

      final response = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        additionalData: {
          'birth_date': formattedDate,
          'barangay': barangay,
          'philhealth_id': philhealthId,
          'is_profile_complete': true,
        },
      );

      if (response.session != null && response.user != null) {
        final profile = await _userRepository.getUserProfile(response.user!.id);
        emit(Authenticated(response.user!, profile: profile));
      } else if (response.user != null) {
        emit(AuthError("Please check your email to confirm your account."));
        emit(Unauthenticated());
      } else {
        emit(AuthError("Registration failed."));
        emit(Unauthenticated());
      }
      
    } catch (e) {
      debugPrint('Registration error: $e');
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      emit(AuthError("Logout failed: $e"));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

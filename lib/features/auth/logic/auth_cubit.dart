import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/services/notification_service.dart';
import '../data/models/user_model.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_user_repository.dart';

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

class AuthEmailVerified extends AuthState {
  final sb.User user;
  AuthEmailVerified(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;
  StreamSubscription<sb.AuthState>? _authStateSubscription;

  AuthCubit({
    required IAuthRepository authRepository,
    required IUserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        super(AuthInitial()) {
    _init();
  }

  Future<void> _init() async {
    final sb.User? initialUser = _authRepository.currentUser;
    if (initialUser != null) {
      await _handleUserAuthenticated(initialUser);
    } else {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (state is AuthInitial) {
        emit(Unauthenticated());
      }
    }

    _authStateSubscription = _authRepository.authStateChanges.listen(
      (data) async {
        try {
          final sb.User? user = data.session?.user;
          final sb.AuthChangeEvent event = data.event;
          
          if (user != null) {
            if (event == sb.AuthChangeEvent.signedIn && state is! AuthLoading && state is! Authenticated) {
              emit(AuthEmailVerified(user));
              return;
            }
            await _handleUserAuthenticated(user);
          } else {
            if (state is! AuthLoading) {
              emit(Unauthenticated());
            }
          }
        } catch (e) {
          if (state is AuthInitial) emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _handleUserAuthenticated(sb.User user) async {
    try {
      final profile = await _userRepository.getUserProfile(user.id);
      try {
        final fcmToken = await NotificationService.getFCMToken();
        if (fcmToken != null) {
          await _userRepository.updateFCMToken(user.id, fcmToken);
        }
      } catch (e) {}
      emit(Authenticated(user, profile: profile));
    } catch (e) {
      emit(Authenticated(user));
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is sb.AuthException) return e.message;
    return e.toString();
  }

  Future<void> login(String identity, String password, {bool isPhoneLogin = false}) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.signIn(
        email: isPhoneLogin ? null : identity,
        phone: isPhoneLogin ? identity : null,
        password: password,
      );
      if (response.user != null) await _handleUserAuthenticated(response.user!);
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
      emit(Unauthenticated());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? birthDate,
    String? barangay,
    String? philhealthId,
  }) async {
    print('ATAMAN_DEBUG: Registering $email');
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
        fullName: "$firstName $lastName",
        phoneNumber: phoneNumber,
        additionalData: {
          'first_name': firstName,
          'last_name': lastName,
          'birth_date': formattedDate,
          'barangay': barangay,
          'philhealth_id': philhealthId,
          'is_profile_complete': true,
        },
      );

      print('ATAMAN_DEBUG: User Created with ID: ${response.user?.id}');

      if (response.session == null && response.user != null) {
        print('ATAMAN_DEBUG: Confirmation Email Required');
        emit(AuthError("Please check your email to confirm your account."));
      } else if (response.user == null) {
        print('ATAMAN_DEBUG: No User object returned');
        emit(AuthError("Registration failed: No user record created."));
      }
    } catch (e) {
      print('ATAMAN_DEBUG: ERROR -> $e');
      emit(AuthError(_handleAuthError(e)));
      emit(Unauthenticated());
    }
  }

  void refreshProfile(UserModel profile) {
    if (state is Authenticated) {
      emit(Authenticated((state as Authenticated).user, profile: profile));
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      await _userRepository.updateProfile(user);
      final sb.User? currentUser = _authRepository.currentUser;
      if (currentUser != null) await _handleUserAuthenticated(currentUser);
    } catch (e) {
      emit(AuthError("Failed to update profile: $e"));
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

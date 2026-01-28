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
    // Supabase already has a user cached
    final sb.User? initialUser = _authRepository.currentUser;
    if (initialUser != null) {
      debugPrint('Found initial user: ${initialUser.id}');
      await _handleUserAuthenticated(initialUser);
    } else {
      //  Supabase to attempt session recovery
      await Future.delayed(const Duration(milliseconds: 1500));
      if (state is AuthInitial) {
        debugPrint('No session recovered. Emitting Unauthenticated to unblock splash.');
        emit(Unauthenticated());
      }
    }

    // Handle future sign-ins/outs
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (data) async {
        try {
          final sb.User? user = data.session?.user;
          final sb.AuthChangeEvent event = data.event;

          debugPrint('Auth State Change Event: $event');
          
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
          debugPrint('Error in auth state change: $e');
          if (state is AuthInitial) emit(Unauthenticated());
        }
      },
      onError: (err) {
        debugPrint('Auth stream error: $err');
        if (state is AuthInitial) emit(Unauthenticated());
      }
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
      } catch (e) {
        debugPrint('Error updating FCM token during init: $e');
      }

      emit(Authenticated(user, profile: profile));
    } catch (e) {
      debugPrint('Authenticated user detected, but profile fetch failed: $e');
      // If profile fails (e.g. network), still emit Authenticated so user isn't kicked out
      emit(Authenticated(user));
    }
  }

  String _handleAuthError(dynamic e) {
    final String errorString = e.toString().toLowerCase();
    if (errorString.contains('weak password')) return "Password is too weak.";
    if (errorString.contains('invalid login credentials')) return "Incorrect email or password.";
    if (errorString.contains('network') || errorString.contains('socketexception')) return "Connection failed.";
    return "Something went wrong. Please try again later.";
  }

  Future<void> login(String identity, String password, {bool isPhoneLogin = false}) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.signIn(
        email: isPhoneLogin ? null : identity,
        phone: isPhoneLogin ? identity : null,
        password: password,
      );

      if (response.user != null) {
        await _handleUserAuthenticated(response.user!);
      }
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
    emit(AuthLoading());
    try {
      String? formattedDate = birthDate;
      if (birthDate != null && birthDate.contains('/')) {
        final parts = birthDate.split('/').map((e) => e.trim()).toList();
        if (parts.length == 3) {
          formattedDate = "${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}";
        }
      }

      // Combine for full_name as fallback/legacy support
      final String fullName = "$firstName $lastName";

      final response = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
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

      if (response.session == null && response.user != null) {
        emit(AuthError("Please check your email to confirm your account."));
      } else if (response.session == null) {
        emit(AuthError("Registration failed."));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
      emit(Unauthenticated());
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      await _userRepository.updateProfile(user);
      final sb.User? currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        await _handleUserAuthenticated(currentUser);
      }
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

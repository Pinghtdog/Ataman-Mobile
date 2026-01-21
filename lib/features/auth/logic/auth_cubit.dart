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

  void _init() {
    _authStateSubscription = _authRepository.authStateChanges.listen((data) async {
      try {
        final sb.User? user = data.session?.user;
        final sb.AuthChangeEvent event = data.event;

        debugPrint('Auth State Change Event: $event');
        
        if (user != null) {
          // Deep-link sign-in
          if (event == sb.AuthChangeEvent.signedIn && state is! AuthLoading && state is! Authenticated) {
            emit(AuthEmailVerified(user));
            return;
          }

          final profile = await _userRepository.getUserProfile(user.id);
          
          // Update FCM Token
          try {
            final fcmToken = await NotificationService.getFCMToken();
            if (fcmToken != null) {
              await _userRepository.updateFCMToken(user.id, fcmToken);
            }
          } catch (e) {
            debugPrint('Error updating FCM token during init: $e');
          }

          emit(Authenticated(user, profile: profile));
        } else {
          if (state is! AuthLoading && state is! AuthError) {
            emit(Unauthenticated());
          }
        }
      } catch (e) {
        debugPrint('Error in auth state change: $e');
      }
    });
  }

  String _handleAuthError(dynamic e) {
    final String errorString = e.toString().toLowerCase();
    
    if (errorString.contains('weak password')) {
      return "Password is too weak. It must include uppercase, lowercase, numbers, and special characters.";
    } else if (errorString.contains('invalid login credentials')) {
      return "The email or password you entered is incorrect.";
    } else if (errorString.contains('user already exists')) {
      return "This email is already registered. Please try logging in.";
    } else if (errorString.contains('network') || errorString.contains('socketexception')) {
      return "Connection failed. Please check your internet and try again.";
    } else if (errorString.contains('email not confirmed')) {
      return "Please check your email to confirm your account.";
    }
    
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
        try {
          final fcmToken = await NotificationService.getFCMToken();
          if (fcmToken != null) {
            await _userRepository.updateFCMToken(response.user!.id, fcmToken);
          }
        } catch (e) {
          debugPrint('Error updating FCM token on login: $e');
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      emit(AuthError(_handleAuthError(e)));
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

      if (response.session == null && response.user != null) {
        emit(AuthError("Please check your email to confirm your account."));
      } else if (response.session == null) {
        emit(AuthError("Registration failed. Please try again."));
        emit(Unauthenticated());
      }
      
    } catch (e) {
      debugPrint('Registration error: $e');
      emit(AuthError(_handleAuthError(e)));
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

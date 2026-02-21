import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/services/notification_service.dart';
import '../../../core/services/mynaga_service.dart';
import '../../../injector.dart';
import '../data/models/user_model.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_user_repository.dart';

/// Base class for all authentication states.
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// The initial state before any authentication check has occurred.
class AuthInitial extends AuthState {}

/// State emitted while an authentication operation (login, register, etc.) is in progress.
class AuthLoading extends AuthState {}

/// State emitted when a user is successfully authenticated and their profile is loaded.
class Authenticated extends AuthState {
  /// The underlying Supabase user object.
  final sb.User user;
  /// The local application user model containing profile details.
  final UserModel? profile;

  Authenticated(this.user, {this.profile});

  @override
  List<Object?> get props => [user, profile];
}

/// State emitted when an email verification event is detected but the profile is not yet fully synchronized.
class AuthEmailVerified extends AuthState {
  /// The underlying Supabase user object.
  final sb.User user;
  AuthEmailVerified(this.user);
  @override
  List<Object?> get props => [user];
}

/// State emitted when the user is not logged in.
class Unauthenticated extends AuthState {}

/// State emitted when an error occurs during an authentication process.
class AuthError extends AuthState {
  /// The human-readable error message.
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// [AuthCubit] manages the authentication lifecycle and user session state.
///
/// It coordinates with [IAuthRepository] for session management and [IUserRepository] 
/// for profile data persistence. It also handles integration with [MyNagaService] 
/// for identity-based authentication.
class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;
  final MyNagaService _myNagaService;
  StreamSubscription<sb.AuthState>? _authStateSubscription;

  AuthCubit({
    required IAuthRepository authRepository,
    required IUserRepository userRepository,
    MyNagaService? myNagaService,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        _myNagaService = myNagaService ?? MyNagaService(),
        super(AuthInitial()) {
    _init();
  }

  /// Initializes the cubit by checking for an existing session and listening to auth state changes.
  Future<void> _init() async {
    final sb.User? initialUser = _authRepository.currentUser;
    if (initialUser != null) {
      await _handleUserAuthenticated(initialUser);
    } else {
      // Artificial delay for splash screen consistency.
      await Future.delayed(const Duration(milliseconds: 1500));
      if (state is AuthInitial) {
        emit(Unauthenticated());
      }
    }

    // Listen to Supabase Auth state changes (signed in, signed out, etc.)
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

  /// Orchestrates the post-authentication workflow.
  /// 
  /// Fetches the user's [UserModel] profile and registers the FCM token for 
  /// push notifications before emitting the [Authenticated] state.
  Future<void> _handleUserAuthenticated(sb.User user) async {
    try {
      final profile = await _userRepository.getUserProfile(user.id);
      try {
        final fcmToken = await NotificationService.getFCMToken();
        if (fcmToken != null) {
          await _userRepository.updateFCMToken(user.id, fcmToken);
        }
      } catch (e) {
        // Log FCM update failure but don't block authentication
      }
      emit(Authenticated(user, profile: profile));
    } catch (e) {
      emit(Authenticated(user));
    }
  }

  /// Manually triggers a profile refresh from the database.
  Future<void> getProfile() async {
    final sb.User? user = _authRepository.currentUser;
    if (user != null) {
      await _handleUserAuthenticated(user);
    }
  }

  /// Transforms raw exceptions into user-friendly error messages.
  /// 
  /// Specifically handles [SocketException] and network-related errors.
  String _handleAuthError(dynamic e) {
    if (e is sb.AuthException) return e.message;
    if (e is SocketException || e.toString().contains('SocketException') || e.toString().contains('host lookup')) {
      return "Network connection error. Please check your internet and try again.";
    }
    if (e.toString().contains('Connection closed')) {
      return "Connection lost. Please try again.";
    }
    return e.toString();
  }

  /// Authenticates a user using their email or phone number.
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

  /// Registers a new user and creates their initial profile record.
  /// 
  /// Automatically formats birth dates and handles initial profile completion flags.
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? middleName,
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
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
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
      } else if (response.user == null) {
        emit(AuthError("Registration failed: No user record created."));
      }
    } catch (e) {
      emit(AuthError(_handleAuthError(e)));
    }
  }

  /// Performs authentication via the MyNaga citizen platform.
  /// 
  /// Fetches citizen data using a secure code and signs in to the Ataman 
  /// platform using synchronized credentials.
  Future<void> connectMyNaga() async {
    emit(AuthLoading());
    try {
      final citizenData = await _myNagaService.fetchCitizenProfile("MOCK_CODE_123");
      
      // Log in using the credentials from the service
      final response = await _authRepository.signIn(
        email: citizenData['email'],
        password: "password123", // In real life, this would be a secure token exchange
      );

      if (response.user != null) {
        await _handleUserAuthenticated(response.user!);
      }
    } catch (e) {
      emit(AuthError("MyNaga connection failed: ${e.toString()}"));
      emit(Unauthenticated());
    }
  }

  /// Locally updates the cached profile object without re-fetching from the database.
  void refreshProfile(UserModel profile) {
    if (state is Authenticated) {
      emit(Authenticated((state as Authenticated).user, profile: profile));
    }
  }

  /// Persists profile updates to the database and refreshes the current session state.
  Future<void> updateProfile(UserModel user) async {
    try {
      await _userRepository.updateProfile(user);
      final sb.User? currentUser = _authRepository.currentUser;
      if (currentUser != null) await _handleUserAuthenticated(currentUser);
    } catch (e) {
      emit(AuthError("Failed to update profile: $e"));
    }
  }

  /// Terminates the current user session and clears all authentication state.
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

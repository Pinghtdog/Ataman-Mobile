import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'constants/constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/auth_selection_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/id_verification_screen.dart';
import 'screens/auth/register_email_screen.dart';
import 'screens/ataman_base_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/triage/triage_input_screen.dart';
import 'screens/triage/triage_result_screen.dart';

import 'logic/auth/auth_cubit.dart';
import 'logic/triage/triage_cubit.dart';
import 'logic/facility/facility_cubit.dart';
import 'logic/booking/booking_cubit.dart';
import 'logic/emergency/emergency_cubit.dart';
import 'logic/profile/profile_cubit.dart';

import 'data/models/triage_model.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/triage_repository.dart';
import 'data/repositories/facility_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/emergency_repository.dart';

import 'utils/injector.dart';
import 'services/notification_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isInitialized = false;

  try {
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception("Missing Supabase credentials in .env file");
    }

    HttpOverrides.global = MyHttpOverrides();
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    if (geminiApiKey != null) {
      Gemini.init(apiKey: geminiApiKey);
    }

    await Firebase.initializeApp();
    await NotificationService.initialize();
    
    await initInjector();
    isInitialized = true;
  } catch (e) {
    debugPrint("CRITICAL ERROR: $e");
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(AtamanApp(isInitialized: isInitialized));
}

class AtamanApp extends StatelessWidget {
  final bool isInitialized;
  const AtamanApp({super.key, required this.isInitialized});

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Configuration Error\nPlease ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in your .env file.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(
            authRepository: getIt<AuthRepository>(),
            userRepository: getIt<UserRepository>(),
          ),
        ),
        BlocProvider<TriageCubit>(
          create: (context) => TriageCubit(
            triageRepository: getIt<TriageRepository>(),
          ),
        ),
        BlocProvider<FacilityCubit>(
          create: (context) => FacilityCubit(
            facilityRepository: getIt<FacilityRepository>(),
          ),
        ),
        BlocProvider<BookingCubit>(
          create: (context) => BookingCubit(
            bookingRepository: getIt<BookingRepository>(),
          ),
        ),
        BlocProvider<EmergencyCubit>(
          create: (context) => EmergencyCubit(
            emergencyRepository: getIt<EmergencyRepository>(),
          ),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            userRepository: getIt<UserRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.triageResult) {
            final result = settings.arguments as TriageResult;
            return MaterialPageRoute(
              builder: (context) => TriageResultScreen(result: result),
            );
          }
          return null;
        },
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.authSelection: (context) => const AuthSelectionScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.verifyId: (context) => const IdVerificationScreen(),
          AppRoutes.registerEmail: (context) => const RegisterEmailScreen(),
          AppRoutes.home: (context) => const AtamanBaseScreen(),
          AppRoutes.triage: (context) => const TriageInputScreen(),
        },
      ),
    );
  }
}

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/repositories/user_repository.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/presentation/screens/auth_selection_screen.dart';
import 'features/auth/presentation/screens/id_verification_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_email_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/booking/data/repositories/booking_repository.dart';
import 'features/booking/logic/booking_cubit.dart';
import 'features/booking/presentation/screens/my_appointments_screen.dart';
import 'features/emergency/data/repositories/emergency_repository.dart';
import 'features/emergency/logic/emergency_cubit.dart';
import 'features/emergency/presentation/screens/emergency_request_screen.dart';
import 'features/facility/data/repositories/facility_repository.dart';
import 'features/facility/logic/facility_cubit.dart';
import 'features/home/presentation/screens/ataman_base_screen.dart';
import 'features/medical_records/data/repositories/prescription_repository.dart';
import 'features/profile/logic/profile_cubit.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/telemedicine/logic/prescription_cubit.dart';
import 'features/triage/data/models/triage_model.dart';
import 'features/triage/data/repositories/triage_repository.dart';
import 'features/triage/logic/triage_cubit.dart';
import 'features/triage/presentation/screens/triage_input_screen.dart';
import 'features/triage/presentation/screens/triage_result_screen.dart';
import 'injector.dart';


//ako pa ni tarongon ang folders kay samok basin nice core(mga services, utiltie etc...)
//then feature(inside feature folder kay ang mga features
//e.g. telemed(inside telemed is the repo, data, logic, etc)

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
        BlocProvider<PrescriptionCubit>(
          create: (context) => PrescriptionCubit(
            prescriptionRepository: getIt<PrescriptionRepository>(),
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
          AppRoutes.emergency: (context) => const EmergencyRequestScreen(),
          AppRoutes.myAppointments: (context) => const MyAppointmentsScreen(),
        },
      ),
    );
  }
}

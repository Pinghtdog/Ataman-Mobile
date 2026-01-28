import 'package:ataman/features/vaccination/presentation/screens/book_vaccination_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/constants.dart';
import 'core/services/service_initializer.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/domain/repositories/i_user_repository.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/presentation/screens/auth_selection_screen.dart';
import 'features/auth/presentation/screens/id_verification_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/patient_enrollment_screen.dart';
import 'features/auth/presentation/screens/register_email_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/booking/data/models/booking_model.dart';
import 'features/booking/data/repositories/booking_repository.dart';
import 'features/booking/logic/booking_cubit.dart';
import 'features/booking/presentation/screens/booking_details_screen.dart';
import 'features/booking/presentation/screens/my_appointments_screen.dart';
import 'features/emergency/data/repositories/emergency_repository.dart';
import 'features/emergency/logic/emergency_cubit.dart';
import 'features/emergency/presentation/screens/emergency_request_screen.dart';
import 'features/facility/data/models/facility_model.dart';
import 'features/facility/data/repositories/facility_repository.dart';
import 'features/facility/logic/facility_cubit.dart';
import 'features/facility/logic/facility_state.dart';
import 'features/home/presentation/screens/ataman_base_screen.dart';
import 'features/medical_records/data/repositories/referral_repository.dart';
import 'features/medical_records/presentation/screens/medical_history_screen.dart';
import 'features/notification/data/repositories/notification_repository.dart';
import 'features/notification/logic/notification_cubit.dart';
import 'features/notification/notifications_screen.dart';
import 'features/medical_records/data/repositories/prescription_repository.dart';
import 'features/profile/logic/profile_cubit.dart';
import 'features/profile/presentation/screens/family_members_screen.dart';
import 'features/profile/presentation/screens/language_screen.dart';
import 'features/profile/presentation/screens/settings/change_password_screen.dart';
import 'features/profile/presentation/screens/settings/notifications_settings_screen.dart';
import 'features/profile/presentation/screens/settings_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/telemedicine/domain/repositories/i_telemedicine_repository.dart';
import 'features/telemedicine/logic/prescription_cubit.dart';
import 'features/telemedicine/logic/telemedicine_cubit.dart';
import 'features/telemedicine/presentation/screens/general_consult_screen.dart';
import 'features/telemedicine/presentation/screens/reproductive_health_screen.dart';
import 'features/telemedicine/presentation/screens/telemedicine_screen.dart';
import 'features/telemedicine/presentation/screens/video_call_screen.dart';
import 'features/triage/data/models/triage_model.dart';
import 'features/triage/domain/repositories/i_triage_repository.dart';
import 'features/triage/logic/triage_cubit.dart';
import 'features/triage/presentation/screens/triage_input_screen.dart';
import 'features/triage/presentation/screens/triage_result_screen.dart';
import 'features/vaccination/presentation/screens/vaccination_screen.dart';
import 'injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final bool isInitialized = await ServiceInitializer.initialize();

  runApp(AtamanApp(isInitialized: isInitialized));
}

class AtamanApp extends StatelessWidget {
  final bool isInitialized;
  const AtamanApp({super.key, required this.isInitialized});

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const _ErrorApp();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(
            authRepository: getIt<IAuthRepository>(),
            userRepository: getIt<IUserRepository>(),
          ),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(userRepository: getIt<IUserRepository>()),
        ),
        BlocProvider<BookingCubit>(
          create: (context) => BookingCubit(
            bookingRepository: getIt<BookingRepository>(),
            referralRepository: getIt<ReferralRepository>(),
          ),
        ),
        BlocProvider<NotificationCubit>(
          create: (context) => NotificationCubit(repository: getIt<NotificationRepository>())..loadNotifications(),
        ),
        BlocProvider<TelemedicineCubit>(
          create: (context) => TelemedicineCubit(getIt<ITelemedicineRepository>()),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: _onGenerateRoute,
        routes: _appRoutes,
      ),
    );
  }

  Route? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.triageResult:
        final result = settings.arguments as TriageResult;
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => TriageCubit(triageRepository: getIt<ITriageRepository>()),
            child: TriageResultScreen(result: result),
          ),
        );
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => FacilityCubit(facilityRepository: getIt<FacilityRepository>())),
              BlocProvider(create: (context) => PrescriptionCubit(prescriptionRepository: getIt<PrescriptionRepository>())),
            ],
            child: const AtamanBaseScreen(),
          ),
        );
      case AppRoutes.videoCall:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            callId: args['callId'],
            userId: args['userId'],
            isCaller: args['isCaller'],
          ),
        );
      case AppRoutes.patientEnrollment:
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (context) => PatientEnrollmentScreen(user: user),
        );
      case AppRoutes.bookingDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => BookingDetailsScreen(
            facility: args['facility'] as Facility,
            triageResult: args['triageResult'] as TriageResult?,
          ),
        );
      default:
        return null;
    }
  }

  Map<String, WidgetBuilder> get _appRoutes => {
    AppRoutes.splash: (context) => const SplashScreen(),
    AppRoutes.authSelection: (context) => const AuthSelectionScreen(),
    AppRoutes.login: (context) => const LoginScreen(),
    AppRoutes.register: (context) => const RegisterScreen(),
    AppRoutes.verifyId: (context) => const IdVerificationScreen(),
    AppRoutes.registerEmail: (context) => const RegisterEmailScreen(),
    AppRoutes.notifications: (context) => const NotificationsScreen(),
    AppRoutes.triage: (context) => BlocProvider(
      create: (context) => TriageCubit(triageRepository: getIt<ITriageRepository>()),
      child: const TriageInputScreen(),
    ),
    AppRoutes.emergency: (context) => BlocProvider(
      create: (context) => EmergencyCubit(emergencyRepository: getIt<EmergencyRepository>()),
      child: const EmergencyRequestScreen(),
    ),
    AppRoutes.myAppointments: (context) => const MyAppointmentsScreen(),
    AppRoutes.vaccination: (context) => const VaccinationScreen(),
    AppRoutes.bookVaccination: (context) => const BookVaccinationScreen(),
    AppRoutes.telemedicine: (context) => const TelemedicineScreen(),
    AppRoutes.reproductiveHealth: (context) => const ReproductiveHealthScreen(),
    AppRoutes.generalConsult: (context) => const GeneralConsultScreen(),
    AppRoutes.familyMembers: (context) => const FamilyMembersScreen(),
    AppRoutes.medicalHistory: (context) => const MedicalHistoryScreen(),
    AppRoutes.settings: (context) => const SettingsScreen(),
    AppRoutes.changePassword: (context) => const ChangePasswordScreen(),
    AppRoutes.notificationSettings: (context) => const NotificationsSettingsScreen(),
    AppRoutes.language: (context) => const LanguageScreen(),
  };
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Configuration Error\nPlease ensure all environment variables are set correctly in your .env file.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

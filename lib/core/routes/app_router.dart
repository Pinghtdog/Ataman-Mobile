import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/screens/auth_selection_screen.dart';
import '../../features/auth/presentation/screens/id_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/patient_enrollment_screen.dart';
import '../../features/auth/presentation/screens/register_email_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/booking/presentation/screens/booking_details_screen.dart';
import '../../features/booking/presentation/screens/my_appointments_screen.dart';
import '../../features/emergency/logic/emergency_cubit.dart';
import '../../features/emergency/presentation/screens/emergency_request_screen.dart';
import '../../features/emergency/data/repositories/emergency_repository.dart';
import '../../features/facility/logic/facility_cubit.dart';
import '../../features/facility/data/repositories/facility_repository.dart';
import '../../features/home/presentation/screens/ataman_base_screen.dart';
import '../../features/medical_records/presentation/screens/medical_history_screen.dart';
import '../../features/medical_records/presentation/screens/referrals_screen.dart';
import '../../features/medicine_access/presentation/screens/hospital_availability_screen.dart';
import '../../features/medicine_access/presentation/screens/medicine_access_screen.dart';
import '../../features/notification/notifications_screen.dart';
import '../../features/profile/presentation/screens/family_members_screen.dart';
import '../../features/profile/presentation/screens/language_screen.dart';
import '../../features/profile/presentation/screens/settings/change_password_screen.dart';
import '../../features/profile/presentation/screens/settings/notifications_settings_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/telemedicine/logic/prescription_cubit.dart';
import '../../features/telemedicine/presentation/screens/general_consult_screen.dart';
import '../../features/telemedicine/presentation/screens/reproductive_health_screen.dart';
import '../../features/telemedicine/presentation/screens/telemedicine_screen.dart';
import '../../features/telemedicine/presentation/screens/video_call_screen.dart';
import '../../features/triage/logic/triage_cubit.dart';
import '../../features/triage/domain/repositories/i_triage_repository.dart';
import '../../features/triage/presentation/screens/triage_input_screen.dart';
import '../../features/triage/presentation/screens/triage_result_screen.dart';
import '../../features/vaccination/presentation/screens/book_vaccination_screen.dart';
import '../../features/vaccination/presentation/screens/vaccination_confirmation_screen.dart';
import '../../features/vaccination/presentation/screens/vaccination_record_screen.dart';
import '../../features/vaccination/presentation/screens/vaccination_screen.dart';
import '../../features/health_alerts/presentation/screens/health_alerts_screen.dart';
import '../../features/medical_records/data/repositories/referral_repository.dart';
import '../../features/medical_records/data/repositories/prescription_repository.dart';
import '../constants/app_routes.dart';
import '../../injector.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.authSelection:
        return MaterialPageRoute(builder: (_) => const AuthSelectionScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case AppRoutes.verifyId:
        return MaterialPageRoute(builder: (_) => const IdVerificationScreen());

      case AppRoutes.registerEmail:
        return MaterialPageRoute(builder: (_) => const RegisterEmailScreen());

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                  create: (context) => FacilityCubit(
                      facilityRepository: getIt<FacilityRepository>())),
              BlocProvider(
                  create: (context) => PrescriptionCubit(
                      prescriptionRepository: getIt<PrescriptionRepository>())),
            ],
            child: const AtamanBaseScreen(),
          ),
        );

      case AppRoutes.triage:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) =>
                TriageCubit(triageRepository: getIt<ITriageRepository>()),
            child: const TriageInputScreen(),
          ),
        );

      case AppRoutes.triageResult:
        final result = settings.arguments as dynamic; // TriageResult
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) =>
                TriageCubit(triageRepository: getIt<ITriageRepository>()),
            child: TriageResultScreen(result: result),
          ),
        );

      case AppRoutes.emergency:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => EmergencyCubit(
                emergencyRepository: getIt<EmergencyRepository>()),
            child: const EmergencyRequestScreen(),
          ),
        );

      case AppRoutes.videoCall:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            callId: args['callId'],
            userId: args['userId'],
            userName: args['userName'] ?? 'User',
            isCaller: args['isCaller'],
          ),
        );

      case AppRoutes.patientEnrollment:
        final user = settings.arguments as dynamic; // UserModel
        return MaterialPageRoute(
            builder: (_) => PatientEnrollmentScreen(user: user));

      case AppRoutes.bookingDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(
            facility: args['facility'],
            triageResult: args['triageResult'],
          ),
        );

      case AppRoutes.hospitalAvailability:
        final medicineName = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) =>
                HospitalAvailabilityScreen(medicineName: medicineName));

      case AppRoutes.vaccinationConfirmation:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => VaccinationConfirmationScreen(bookingData: args));

      case AppRoutes.myAppointments:
        return MaterialPageRoute(builder: (_) => const MyAppointmentsScreen());

      case AppRoutes.vaccination:
        return MaterialPageRoute(builder: (_) => const VaccinationScreen());

      case AppRoutes.bookVaccination:
        return MaterialPageRoute(builder: (_) => const BookVaccinationScreen());

      case AppRoutes.vaccinationRecord:
        return MaterialPageRoute(
            builder: (_) => const VaccinationRecordScreen());

      case AppRoutes.telemedicine:
        return MaterialPageRoute(builder: (_) => const TelemedicineScreen());

      case AppRoutes.reproductiveHealth:
        return MaterialPageRoute(
            builder: (_) => const ReproductiveHealthScreen());

      case AppRoutes.generalConsult:
        return MaterialPageRoute(builder: (_) => const GeneralConsultScreen());

      case AppRoutes.familyMembers:
        return MaterialPageRoute(builder: (_) => const FamilyMembersScreen());

      case AppRoutes.medicalHistory:
        return MaterialPageRoute(builder: (_) => const MedicalHistoryScreen());

      case AppRoutes.referrals:
        return MaterialPageRoute(builder: (_) => const ReferralsScreen());

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case AppRoutes.notificationSettings:
        return MaterialPageRoute(
            builder: (_) => const NotificationsSettingsScreen());

      case AppRoutes.language:
        return MaterialPageRoute(builder: (_) => const LanguageScreen());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case AppRoutes.medicineAccess:
        return MaterialPageRoute(builder: (_) => const MedicineAccessScreen());

      case AppRoutes.healthAlerts:
        return MaterialPageRoute(builder: (_) => const HealthAlertsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

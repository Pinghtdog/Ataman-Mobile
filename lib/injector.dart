import 'package:get_it/get_it.dart';
import 'core/services/gemini_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/repositories/user_repository.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/domain/repositories/i_user_repository.dart';
import 'features/booking/data/repositories/booking_repository.dart';
import 'features/emergency/data/repositories/emergency_repository.dart';
import 'features/facility/data/repositories/facility_repository.dart';
import 'features/medical_records/data/repositories/prescription_repository.dart';
import 'features/notification/data/repositories/notification_repository.dart';
import 'features/triage/data/repositories/triage_repository.dart';
import 'features/triage/data/services/triage_service.dart';
import 'features/triage/domain/repositories/i_triage_repository.dart';

final getIt = GetIt.instance;

Future<void> initInjector() async {
  // Services
  getIt.registerLazySingleton<GeminiService>(() => GeminiService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<TriageService>(
    () => TriageService(getIt<GeminiService>(), getIt<IUserRepository>()),
  );

  // Repositories - Interfaces
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(authService: getIt<AuthService>()),
  );
  getIt.registerLazySingleton<IUserRepository>(() => UserRepository());
  
  getIt.registerLazySingleton<ITriageRepository>(
    () => TriageRepository(getIt<TriageService>()),
  );
  
  // Concrete Repositories
  getIt.registerLazySingleton<FacilityRepository>(() => FacilityRepository());
  getIt.registerLazySingleton<BookingRepository>(() => BookingRepository());
  getIt.registerLazySingleton<EmergencyRepository>(() => EmergencyRepository());
  getIt.registerLazySingleton<PrescriptionRepository>(() => PrescriptionRepository());
  getIt.registerLazySingleton<NotificationRepository>(() => NotificationRepository());
}

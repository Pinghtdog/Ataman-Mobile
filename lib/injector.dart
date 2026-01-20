import 'package:get_it/get_it.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/repositories/user_repository.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/booking/data/repositories/booking_repository.dart';
import 'features/emergency/data/repositories/emergency_repository.dart';
import 'features/facility/data/repositories/facility_repository.dart';
import 'features/medical_records/data/repositories/prescription_repository.dart';
import 'features/triage/data/repositories/triage_repository.dart';
import 'features/triage/data/services/triage_service.dart';

final getIt = GetIt.instance;

Future<void> initInjector() async {
  // Services
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<TriageService>(() => TriageService());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(authService: getIt<AuthService>()),
  );
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());
  getIt.registerLazySingleton<TriageRepository>(
    () => TriageRepository(getIt<TriageService>()),
  );
  getIt.registerLazySingleton<FacilityRepository>(() => FacilityRepository());
  getIt.registerLazySingleton<BookingRepository>(() => BookingRepository());
  getIt.registerLazySingleton<EmergencyRepository>(() => EmergencyRepository());
  getIt.registerLazySingleton<PrescriptionRepository>(() => PrescriptionRepository());
}

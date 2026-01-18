import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/triage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/triage_repository.dart';
import '../data/repositories/facility_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/emergency_repository.dart';

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
}

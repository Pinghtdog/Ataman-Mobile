import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';

final getIt = GetIt.instance;

Future<void> initInjector() async {
  // Services
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(authService: getIt<AuthService>()),
  );
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());
}

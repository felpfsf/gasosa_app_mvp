import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gasosa_app/application/commands/vehicles/create_or_update_vehicle_command.dart';
import 'package:gasosa_app/application/commands/vehicles/delete_vehicle_command.dart';
import 'package:gasosa_app/application/commands/vehicles/load_vehicles_command.dart';
import 'package:gasosa_app/application/loggin_with_google_command.dart';
import 'package:gasosa_app/application/login_email_password_command.dart';
import 'package:gasosa_app/application/register_command.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/repositories/user_repository_impl.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository_impl.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:gasosa_app/domain/services/firebase_auth_service.dart';
import 'package:gasosa_app/presentation/screens/auth/viewmodel/login_viewmodel.dart';
import 'package:gasosa_app/presentation/screens/auth/viewmodel/register_viewmodel.dart';
import 'package:gasosa_app/presentation/screens/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  _registerCore();
  await _registerFirebase();
  _registerDatabaseAndDaos();
  _registerRepositories();
  _registerUseCasesAndCommands();
  _registerViewModels();
}

/// 1 - Core/Config
void _registerCore() {
  // AppConfig, Logger, Analytics...
  // Ex: getI.registerLazySingleton<AppConfig>(() => AppConfig.fromEnv());
  getIt.registerLazySingleton<LoadingController>(() => LoadingController());
}

/// 2 - Firebase/Auth
Future<void> _registerFirebase() async {
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Google Sign-In
  final gsi = GoogleSignIn.instance;
  await gsi.initialize();

  // Login silencioso não deve bloquear o app; disparado em background
  // unawaited(gsi.attemptLightweightAuthentication());
  getIt.registerLazySingleton<GoogleSignIn>(() => gsi);

  getIt.registerLazySingleton<AuthService>(
    () => FirebaseAuthService(
      auth: getIt<FirebaseAuth>(),
      google: getIt<GoogleSignIn>(),
    ),
  );
}

/// 3 - Database/DAOs
void _registerDatabaseAndDaos() {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<VehicleDao>(() => VehicleDao(getIt<AppDatabase>()));
}

/// 4 - Repositories
void _registerRepositories() {
  getIt.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(getIt()));
  getIt.registerLazySingleton<VehicleRepository>(() => VehicleRepositoryImpl(getIt()));
}

/// 5 - Use Cases e Commands
void _registerUseCasesAndCommands() {
  getIt.registerFactory(() => LoginWithGoogleCommand(getIt<AuthService>()));
  getIt.registerFactory(() => LoginEmailPasswordCommand(auth: getIt<AuthService>()));
  getIt.registerFactory(() => RegisterCommand(auth: getIt<AuthService>()));

  getIt.registerFactory(() => CreateOrUpdateVehicleCommand(getIt<VehicleRepository>()));
  getIt.registerFactory(() => LoadVehiclesCommand(getIt<VehicleRepository>()));
  getIt.registerFactory(() => DeleteVehicleCommand(getIt<VehicleRepository>()));
}

/// 6 - ViewModels
void _registerViewModels() {
  getIt.registerFactory(
    () => LoginViewModel(
      loginGoogle: getIt<LoginWithGoogleCommand>(),
      loginEmailPassword: getIt<LoginEmailPasswordCommand>(),
      loading: getIt<LoadingController>(),
    ),
  );
  getIt.registerFactory(
    () => RegisterViewModel(
      registerCommand: getIt<RegisterCommand>(),
      loading: getIt<LoadingController>(),
    ),
  );

  getIt.registerFactory(
    () => DashboardViewModel(
      loadVehicles: getIt<LoadVehiclesCommand>(),
      loading: getIt<LoadingController>(),
    ),
  );
}

/// Opcionais

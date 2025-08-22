import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gasosa_app/application/loggin_with_google_command.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/repositories/firebase_auth_repository.dart';
import 'package:gasosa_app/domain/auth/auth_repository.dart';
import 'package:gasosa_app/presentation/screens/auth/viewmodel/login_viewmodel.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  // Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  final gsi = GoogleSignIn.instance;
  await gsi.initialize();

  unawaited(gsi.attemptLightweightAuthentication());
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  getIt.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(
      auth: getIt<FirebaseAuth>(),
      google: getIt<GoogleSignIn>(),
    ),
  );

  getIt.registerFactory(() => LoginWithGoogleCommand(getIt<AuthRepository>()));

  getIt.registerFactory(() => LoginViewmodel(getIt<LoginWithGoogleCommand>()));
}

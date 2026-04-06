import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/firebase_options.dart';
import 'package:gasosa_app/presentation/app.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Captura erros Flutter não tratados → Crashlytics
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Captura erros Dart assíncronos fora da zona Flutter → Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  await initializeDateFormatting('pt_BR');

  try {
    await configureDependencies();
  } catch (e, st) {
    debugPrint('Failed to initialize dependencies: $e\n$st');
    rethrow;
  }

  runApp(const GasosaApp());
}

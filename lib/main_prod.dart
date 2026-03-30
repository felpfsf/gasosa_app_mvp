import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/firebase_options_prod.dart';
import 'package:gasosa_app/flavor.dart';
import 'package:gasosa_app/presentation/app.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('pt_BR');

  Flavor.instance = const Flavor(
    name: 'prod',
    dbName: 'prod_db',
  );

  try {
    await configureDependencies();
  } catch (e, st) {
    debugPrint('Failed to initialize dependencies: $e\n$st');
    rethrow;
  }

  runApp(const GasosaApp());
}

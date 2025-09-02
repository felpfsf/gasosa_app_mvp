import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/firebase_options_dev.dart';
import 'package:gasosa_app/flavor.dart';
import 'package:gasosa_app/presentation/app.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('pt_BR');

  // Flavors
  Flavor.instance = const Flavor(
    name: 'dev',
    dbName: 'dev_db',
  );

  // Inicia a injeção de dependências
  await setupDI();

  runApp(const GasosaApp());
}

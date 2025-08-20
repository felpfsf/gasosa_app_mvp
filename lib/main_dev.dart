import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/firebase_options_dev.dart';
import 'package:gasosa_app/flavor.dart';
import 'package:gasosa_app/presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Flavor.instance = const Flavor(
    name: 'dev',
    dbName: 'dev_db',
  );

  runApp(const GasosaApp());
}

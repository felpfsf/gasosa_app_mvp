import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:gasosa_app/data/local/dao/refuel_dao.dart';
import 'package:gasosa_app/data/local/dao/user_dao.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/presentation/routes/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@module
abstract class RegisterModule {
  // -------------------------
  // Core utils
  // -------------------------
  @lazySingleton
  Uuid get uuid => const Uuid();

  // -------------------------
  // Router
  // -------------------------
  @lazySingleton
  GoRouter get router => appRouter;

  // -------------------------
  // Firebase / Auth
  // -------------------------
  @lazySingleton
  fb.FirebaseAuth get firebaseAuth => fb.FirebaseAuth.instance;

  @preResolve
  @lazySingleton
  Future<GoogleSignIn> get googleSignIn async {
    final gsi = GoogleSignIn.instance;
    await gsi.initialize();
    return gsi;
  }

  // -------------------------
  // Drift — Database
  // -------------------------
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  @lazySingleton
  VehicleDao vehicleDao(AppDatabase db) => VehicleDao(db);

  @lazySingleton
  RefuelDao refuelDao(AppDatabase db) => RefuelDao(db);

  @lazySingleton
  UserDao userDao(AppDatabase db) => UserDao(db);
}

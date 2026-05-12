import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:gasosa_app/data/local/dao/refuel_dao.dart';
import 'package:gasosa_app/data/local/dao/user_dao.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/local/tables/refuel_table.dart';
import 'package:gasosa_app/data/local/tables/user_table.dart';
import 'package:gasosa_app/data/local/tables/vehicle_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Users, Vehicles, Refuels],
  daos: [UserDao, VehicleDao, RefuelDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'gasosa_db'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(vehicles, vehicles.deletedAt);
        await m.addColumn(refuels, refuels.deletedAt);
      }
    },
  );
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:gasosa_app/data/local/dao/refuel_dao.dart';
import 'package:gasosa_app/data/local/dao/user_dao.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/local/tables/refuel_table.dart';
import 'package:gasosa_app/data/local/tables/user_table.dart';
import 'package:gasosa_app/data/local/tables/vehicle_table.dart';
import 'package:gasosa_app/flavor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Users, Vehicles, Refuels],
  daos: [UserDao, VehicleDao, RefuelDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      // if (from == 1 && to == 2) {
      //   await m.addColumn(vehicles, vehicles.fuelType);

      //   await customStatement(
      //     'UPDATE vehicles SET fuel_type = ? WHERE fuel_type IS NULL OR fuel_type = ""',
      //     ['flex'],
      //   );
      // }
    },
  );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, Flavor.instance.dbName));

    return NativeDatabase.createInBackground(file);
  });
}

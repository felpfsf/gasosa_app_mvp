import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/local/tables/refuel_table.dart';

// upsert(RefuelsCompanion)
// deleteById(String id)
// getById(String id)
// getAllByVehicleId(String vehicleId) (orderBy data DESC)
// watchByVehicleId(String vehicleId) (orderBy data DESC)
// getPreviousByVehicleId(String vehicleId, {required int mileage}) OU by date (o que for adotado)

part 'refuel_dao.g.dart';

@DriftAccessor(tables: [Refuels])
class RefuelDao extends DatabaseAccessor<AppDatabase> with _$RefuelDaoMixin {
  RefuelDao(super.db);

  Future<void> upsert(RefuelsCompanion data) async {
    await into(refuels).insertOnConflictUpdate(data);
  }

  Future<RefuelRow?> getById(String id) => (select(refuels)..where((r) => r.id.equals(id))).getSingleOrNull();

  Stream<List<RefuelRow>> watchByVehicleId(String vehicleId) =>
      (select(refuels)
            ..where((r) => r.vehicleId.equals(vehicleId))
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .watch();

  Future<List<RefuelRow>> getAllByVehicleId(String vehicleId) =>
      (select(refuels)..where((r) => r.vehicleId.equals(vehicleId))).get();

  Future<int> deleteById(String id) => (delete(refuels)..where((r) => r.id.equals(id))).go();

  // Future<RefuelRow?> getPreviousByVehicleId(String vehicleId, {required int mileage}) {
  //   return (select(refuels)
  //         ..where((r) => r.vehicleId.equals(vehicleId))
  //         ..where((r) => r.mileage.isBiggerThanValue(mileage))
  //         ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
  //         ..limit(1))
  //       .getSingleOrNull();
  // }

  Future<RefuelRow?> getPreviousByVehicleId(
    String vehicleId, {
    required DateTime createdAt,
    required int mileage,
  }) async {
    final byMileage =
        await (select(refuels)
              ..where((r) => r.vehicleId.equals(vehicleId))
              ..where((r) => r.mileage.isBiggerThanValue(mileage))
              ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    final byDate =
        await (select(refuels)
              ..where((r) => r.vehicleId.equals(vehicleId))
              ..where((r) => r.createdAt.isSmallerThanValue(createdAt))
              ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    return byMileage ?? byDate;
  }
}

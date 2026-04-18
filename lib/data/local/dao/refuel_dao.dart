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

  SimpleSelectStatement<$RefuelsTable, RefuelRow> _active() => select(refuels)..where((r) => r.deletedAt.isNull());

  Future<void> upsert(RefuelsCompanion data) async {
    await into(refuels).insertOnConflictUpdate(data);
  }

  Future<RefuelRow?> getById(String id) => (_active()..where((r) => r.id.equals(id))).getSingleOrNull();

  Stream<List<RefuelRow>> watchByVehicleId(String vehicleId) =>
      (_active()
            ..where((r) => r.vehicleId.equals(vehicleId))
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .watch();

  Future<List<RefuelRow>> getAllByVehicleId(String vehicleId) =>
      (_active()..where((r) => r.vehicleId.equals(vehicleId))).get();

  Future<int> softDeleteById(String id) => (update(refuels)..where((r) => r.id.equals(id))).write(
    RefuelsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())),
  );

  Future<RefuelRow?> getPreviousByMileage(String vehicleId, {required int mileage}) {
    return (_active()
          ..where((r) => r.vehicleId.equals(vehicleId))
          ..where((r) => r.mileage.isBiggerThanValue(mileage))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<RefuelRow?> getPreviousByDate(String vehicleId, {required DateTime createdAt}) {
    return (_active()
          ..where((r) => r.vehicleId.equals(vehicleId))
          ..where((r) => r.createdAt.isSmallerThanValue(createdAt))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Retorna todos os registros (incluindo soft-deleted) para sincronização
  Future<List<RefuelRow>> getAllByVehicleIdIncludingDeleted(String vehicleId) =>
      (select(refuels)..where((r) => r.vehicleId.equals(vehicleId))).get();

  /// Retorna todos os refuels de múltiplos veículos (incluindo soft-deleted) para sync
  Future<List<RefuelRow>> getAllByVehicleIdsIncludingDeleted(List<String> vehicleIds) {
    if (vehicleIds.isEmpty) return Future.value([]);
    return (select(refuels)..where((r) => r.vehicleId.isIn(vehicleIds))).get();
  }
}

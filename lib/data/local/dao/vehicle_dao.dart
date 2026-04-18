import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/local/tables/vehicle_table.dart';

part 'vehicle_dao.g.dart';

@DriftAccessor(tables: [Vehicles])
class VehicleDao extends DatabaseAccessor<AppDatabase> with _$VehicleDaoMixin {
  VehicleDao(super.db);

  SimpleSelectStatement<$VehiclesTable, VehicleRow> _active() => select(vehicles)..where((v) => v.deletedAt.isNull());

  Future<void> upsert(VehiclesCompanion data) async {
    await into(vehicles).insertOnConflictUpdate(data);
  }

  Future<VehicleRow?> getById(String id) => (_active()..where((v) => v.id.equals(id))).getSingleOrNull();

  Stream<List<VehicleRow>> watchAllByUserId(String userId) =>
      (_active()
            ..where((v) => v.userId.equals(userId))
            ..orderBy([(v) => OrderingTerm.asc(v.name)]))
          .watch();

  Future<List<VehicleRow>> getAllByUserId(String userId) => (_active()..where((v) => v.userId.equals(userId))).get();

  Future<int> softDeleteById(String id) => (update(vehicles)..where((v) => v.id.equals(id))).write(
    VehiclesCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())),
  );

  Future<int> softDeleteAllByUserId(String userId) => (update(vehicles)..where((v) => v.userId.equals(userId))).write(
    VehiclesCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())),
  );

  /// Hard delete — usado apenas no deleteAccount (cleanup total)
  Future<int> hardDeleteAllByUserId(String userId) => (delete(vehicles)..where((v) => v.userId.equals(userId))).go();

  Future<bool> existsPlateForUser(String userId, String plate, {String? exceptId}) async {
    final query = _active()..where((v) => v.userId.equals(userId) & v.plate.equals(plate));
    final rows = await query.get();
    if (exceptId == null) return rows.isNotEmpty;
    return rows.any((row) => row.id != exceptId);
  }

  Future<void> touchUpdatedAt(String id) async {
    await (update(vehicles)..where((v) => v.id.equals(id))).write(VehiclesCompanion(updatedAt: Value(DateTime.now())));
  }

  /// Retorna todos os registros (incluindo soft-deleted) para sincronização
  Future<List<VehicleRow>> getAllByUserIdIncludingDeleted(String userId) =>
      (select(vehicles)..where((v) => v.userId.equals(userId))).get();
}

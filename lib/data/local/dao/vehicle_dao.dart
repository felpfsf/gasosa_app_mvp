import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/local/tables/vehicle_table.dart';

part 'vehicle_dao.g.dart';

@DriftAccessor(tables: [Vehicles])
class VehicleDao extends DatabaseAccessor<AppDatabase> with _$VehicleDaoMixin {
  VehicleDao(super.db);

  Future<void> upsert(VehiclesCompanion data) async {
    await into(vehicles).insertOnConflictUpdate(data);
  }

  Future<VehicleRow?> getById(String id) => (select(vehicles)..where((v) => v.id.equals(id))).getSingleOrNull();

  Stream<List<VehicleRow>> watchAllByUserId(String userId) =>
      (select(vehicles)
            ..where((v) => v.userId.equals(userId))
            ..orderBy([(v) => OrderingTerm.asc(v.name)]))
          .watch();

  Future<List<VehicleRow>> getAllByUserId(String userId) =>
      (select(vehicles)..where((v) => v.userId.equals(userId))).get();

  Future<int> deleteById(String id) => (delete(vehicles)..where((v) => v.id.equals(id))).go();

  Future<bool> existsPlateForUser(String userId, String plate, {String? exceptId}) async {
    final query = select(vehicles)..where((v) => v.userId.equals(userId) & v.plate.equals(plate));
    final rows = await query.get();
    if (exceptId == null) return rows.isNotEmpty;
    return rows.any((row) => row.id != exceptId);
  }

  Future<void> touchUpdatedAt(String id) async {
    await (update(vehicles)..where((v) => v.id.equals(id))).write(VehiclesCompanion(updatedAt: Value(DateTime.now())));
  }
}

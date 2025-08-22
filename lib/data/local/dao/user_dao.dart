import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/local/tables/user_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<void> insert(UsersCompanion entity) => into(users).insert(
    entity,
    mode: InsertMode.insertOrReplace,
  );

  Future<UserRow?> getById(String id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<UserRow?> getByEmail(String email) {
    return (select(users)..where((tbl) => tbl.email.equals(email))).getSingleOrNull();
  }

  Future<bool> updateUser(UserRow row) => update(users).replace(row);

  Future<int> upsert(UserRow row) => into(users).insertOnConflictUpdate(row);

  Future<int> deleteById(String id) => (delete(users)..where((tbl) => tbl.id.equals(id))).go();

  Stream<UserRow?> watchById(String id) => (select(users)..where((t) => t.id.equals(id))).watchSingleOrNull();
}

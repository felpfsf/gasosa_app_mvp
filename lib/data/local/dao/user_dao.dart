import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/local/tables/user_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [UserTable])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<void> inser(UserRow row) => into(userTable).insert(row);

  Future<UserRow?> getById(String id) {
    return (select(userTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
}

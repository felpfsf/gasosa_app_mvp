import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/domain/entities/user.dart';

class UserMapper {
  static UsersCompanion toCompanion(UserEntity user) => UsersCompanion(
    id: Value(user.id),
    email: Value(user.email),
    name: Value(user.name),
    photoUrl: Value(user.photoUrl),
  );

  static UserEntity fromData(UserRow row) => UserEntity(
    id: row.id,
    name: row.name,
    email: row.email,
    photoUrl: row.photoUrl,
  );

  static UserRow toData(UserEntity user) => UserRow(
    id: user.id,
    name: user.name,
    email: user.email,
    photoUrl: user.photoUrl,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';

class UserMapper {
  static AuthUser toDomain(UserRow row) => AuthUser(
    row.id,
    row.name,
    row.email,
    photoUrl: row.photoUrl,
  );

  static UsersCompanion toCompanion(AuthUser user) => UsersCompanion(
    id: Value(user.id),
    name: Value(user.name),
    email: Value(user.email),
    photoUrl: Value(user.photoUrl),
    updatedAt: Value(DateTime.now()),
  );
}

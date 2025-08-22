import 'package:drift/drift.dart';

@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().withLength(min: 1, max: 255)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

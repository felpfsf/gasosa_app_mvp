import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/tables/user_table.dart';

@DataClassName('VehicleRow')
class Vehicles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get plate => text().withLength(min: 1, max: 20).nullable()();
  RealColumn get tankCapacity => real().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/tables/user_table.dart';
import 'package:gasosa_app/data/local/tables/vehicle_table.dart';

@DataClassName('RefuelRow')
class Refuels extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get vehicleId => text().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get refuelDate => dateTime()();
  TextColumn get fuelType => text().withLength(min: 1, max: 50)();
  RealColumn get totalValue => real()();
  IntColumn get mileage => integer()();
  RealColumn get liters => real()();
  RealColumn get coldStartLiters => real().nullable()();
  RealColumn get coldStartValue => real().nullable()();
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updateAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

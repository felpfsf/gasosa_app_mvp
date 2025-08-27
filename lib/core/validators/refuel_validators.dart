import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:validatorless/validatorless.dart';

// TextColumn get id => text()();
// TextColumn get userId => text().references(Users, #id)();
// TextColumn get vehicleId => text().references(Vehicles, #id, onDelete: KeyAction.cascade)();
// DateTimeColumn get refuelDate => dateTime()();
// TextColumn get fuelType => text().withLength(min: 1, max: 50)();
// RealColumn get totalValue => real()();
// IntColumn get mileage => integer()();
// RealColumn get liters => real()();
// RealColumn get coldStartLiters => real().nullable()();
// RealColumn get coldStartValue => real().nullable()();
// TextColumn get receiptPath => text().nullable()();
// DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
// DateTimeColumn get updateAt => dateTime().nullable()();

class RefuelValidators {
  static final liters = Validatorless.multiple([
    Validatorless.required('Litros abastecidos é obrigatório'),
    Validatorless.min(1, 'Litros abastecidos deve ser maior que 0'),
    Validatorless.max(100, 'Litros abastecidos deve ser menor que 100'),
  ]);

  static final totalValue = Validatorless.multiple([
    Validatorless.required('Valor total é obrigatório'),
    Validatorless.min(0_01, 'Valor total deve ser maior que 0'),
  ]);

  static final mileage = Validatorless.multiple([
    Validatorless.required('KM é obrigatória'),
    Validatorless.min(0, 'KM deve ser maior ou igual a 0'),
    Validatorless.max(1_000_000, 'KM deve ser menor que 1.000.000'),
  ]);

  static final coldStartLiters = Validatorless.multiple([
    Validatorless.required('Litros partida frio é obrigatório'),
    Validatorless.min(0, 'Litros partida frio deve ser maior ou igual a 0'),
    Validatorless.max(100, 'Litros partida frio deve ser menor que 100'),
  ]);

  static final coldStartValue = Validatorless.multiple([
    Validatorless.required('Valor partida frio é obrigatório'),
    Validatorless.min(0_01, 'Valor partida frio deve ser maior que 0'),
  ]);

  static String? fuelType(FuelType? value) {
    if (value == null) return 'Selecione o tipo de combustível';
    return null;
  }

  static String? date(DateTime? date) {
    if (date == null) return 'Data do abastecimento é obrigatória';
    return null;
  }
}

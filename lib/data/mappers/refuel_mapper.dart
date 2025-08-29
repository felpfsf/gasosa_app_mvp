import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';

class RefuelMapper {
  static RefuelsCompanion toCompanion(RefuelEntity e) => RefuelsCompanion(
    id: Value(e.id),
    vehicleId: Value(e.vehicleId),
    refuelDate: Value(e.refuelDate),
    fuelType: Value(e.fuelType),
    totalValue: Value(e.totalValue),
    mileage: Value(e.mileage),
    liters: Value(e.liters),
    coldStartLiters: Value(e.coldStartLiters),
    coldStartValue: Value(e.coldStartValue),
    receiptPath: Value(e.receiptPath),
    createdAt: Value(e.createdAt),
    updatedAt: Value(e.updatedAt),
  );

  static RefuelEntity toDomain(RefuelRow row) => RefuelEntity(
    id: row.id,
    vehicleId: row.vehicleId,
    refuelDate: row.refuelDate,
    fuelType: row.fuelType,
    totalValue: row.totalValue,
    mileage: row.mileage,
    liters: row.liters,
    coldStartLiters: row.coldStartLiters,
    coldStartValue: row.coldStartValue,
    receiptPath: row.receiptPath,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

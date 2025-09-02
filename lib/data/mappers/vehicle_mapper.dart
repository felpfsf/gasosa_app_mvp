import 'package:drift/drift.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';

class VehicleMapper {
  static VehiclesCompanion toCompanion(VehicleEntity e) => VehiclesCompanion(
    id: Value(e.id),
    userId: Value(e.userId),
    name: Value(e.name),
    plate: Value(e.plate),
    tankCapacity: Value(e.tankCapacity),
    fuelType: Value(e.fuelType.name),
    photoPath: Value(e.photoPath),
    createdAt: Value(e.createdAt),
    updatedAt: Value(e.updatedAt),
  );

  static VehicleEntity toDomain(VehicleRow row) => VehicleEntity(
    id: row.id,
    userId: row.userId,
    name: row.name,
    plate: row.plate,
    tankCapacity: row.tankCapacity,
    fuelType: FuelType.values.firstWhere((e) => e.name == row.fuelType),
    photoPath: row.photoPath,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

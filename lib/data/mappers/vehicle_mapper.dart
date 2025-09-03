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

  static FuelType _stringToFuelType(String? value) {
    if (value == null) return FuelType.flex;

    switch (value.toLowerCase()) {
      case 'gasoline':
        return FuelType.gasoline;
      case 'ethanol':
        return FuelType.ethanol;
      case 'diesel':
        return FuelType.diesel;
      case 'gnv':
        return FuelType.gnv;
      case 'flex':
        return FuelType.flex;
      default:
        return FuelType.flex;
    }
  }

  static VehicleEntity toDomain(VehicleRow row) {
    // print('💜 Mapping VehicleRow to VehicleEntity: id=${row.id}, name=${row.name}, fuelType=${row.fuelType}');

    final fuelType = _stringToFuelType(row.fuelType);
    // print('💜 Mapped fuelType: $fuelType');

    return VehicleEntity(
      id: row.id,
      userId: row.userId,
      name: row.name,
      plate: row.plate,
      tankCapacity: row.tankCapacity,
      fuelType: fuelType,
      photoPath: row.photoPath,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

import 'package:gasosa_app/domain/entities/fuel_type.dart';

class VehicleEntity {
  VehicleEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.fuelType,
    this.plate,
    this.tankCapacity,
    this.photoPath,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final FuelType fuelType;
  final String? plate;
  final double? tankCapacity;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VehicleEntity copyWith({
    String? id,
    String? userId,
    String? name,
    FuelType? fuelType,
    String? plate,
    double? tankCapacity,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      fuelType: fuelType ?? this.fuelType,
      plate: plate ?? this.plate,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

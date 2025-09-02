// id, userId, vehicleId, refuelDate, fuelType, totalValue, mileage, liters, coldStartLiters?, coldStartValue?, receiptPath?, createdAt, updateAt?

import 'package:gasosa_app/domain/entities/fuel_type.dart';

class RefuelEntity {
  RefuelEntity({
    required this.id,
    required this.vehicleId,
    required this.refuelDate,
    required this.fuelType,
    required this.totalValue,
    required this.mileage,
    required this.liters,
    this.coldStartLiters,
    this.coldStartValue,
    this.receiptPath,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String vehicleId;
  final DateTime refuelDate;
  final FuelType fuelType;
  final double totalValue;
  final int mileage;
  final double liters;
  final double? coldStartLiters;
  final double? coldStartValue;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

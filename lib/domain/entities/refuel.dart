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

  RefuelEntity copyWith({
    String? id,
    String? vehicleId,
    DateTime? refuelDate,
    FuelType? fuelType,
    double? totalValue,
    int? mileage,
    double? liters,
    double? coldStartLiters,
    double? coldStartValue,
    String? receiptPath,
    bool clearReceiptPath = false,
    bool clearColdStart = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RefuelEntity(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      refuelDate: refuelDate ?? this.refuelDate,
      fuelType: fuelType ?? this.fuelType,
      totalValue: totalValue ?? this.totalValue,
      mileage: mileage ?? this.mileage,
      liters: liters ?? this.liters,
      coldStartLiters: clearColdStart ? null : (coldStartLiters ?? this.coldStartLiters),
      coldStartValue: clearColdStart ? null : (coldStartValue ?? this.coldStartValue),
      receiptPath: clearReceiptPath ? null : (receiptPath ?? this.receiptPath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

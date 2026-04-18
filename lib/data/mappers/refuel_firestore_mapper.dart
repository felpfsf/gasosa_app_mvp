import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';

class RefuelFirestoreMapper {
  static RefuelEntity fromFirestore(Map<String, dynamic> data) {
    return RefuelEntity(
      id: data['id'] as String,
      vehicleId: data['vehicleId'] as String? ?? '',
      refuelDate: _parseTimestamp(data['refuelDate']),
      fuelType: _parseFuelType(data['fuelType'] as String?),
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0,
      mileage: (data['mileage'] as num?)?.toInt() ?? 0,
      liters: (data['liters'] as num?)?.toDouble() ?? 0,
      coldStartLiters: (data['coldStartLiters'] as num?)?.toDouble(),
      coldStartValue: (data['coldStartValue'] as num?)?.toDouble(),
      receiptPath: data['receiptPath'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseNullableTimestamp(data['updatedAt']),
    );
  }

  static DateTime? deletedAtFromFirestore(Map<String, dynamic> data) => _parseNullableTimestamp(data['deletedAt']);

  static FuelType _parseFuelType(String? value) {
    if (value == null) return FuelType.gasoline;
    return FuelType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FuelType.gasoline,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  static DateTime? _parseNullableTimestamp(dynamic value) {
    if (value == null) return null;
    return _parseTimestamp(value);
  }
}

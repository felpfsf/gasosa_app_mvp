import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';

class VehicleFirestoreMapper {
  static VehicleEntity fromFirestore(Map<String, dynamic> data, String userId) {
    return VehicleEntity(
      id: data['id'] as String,
      userId: userId,
      name: data['name'] as String? ?? '',
      fuelType: _parseFuelType(data['fuelType'] as String?),
      plate: data['plate'] as String?,
      tankCapacity: (data['tankCapacity'] as num?)?.toDouble(),
      photoPath: data['photoPath'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseNullableTimestamp(data['updatedAt']),
    );
  }

  static DateTime? deletedAtFromFirestore(Map<String, dynamic> data) => _parseNullableTimestamp(data['deletedAt']);

  static FuelType _parseFuelType(String? value) {
    if (value == null) return FuelType.flex;
    return FuelType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FuelType.flex,
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

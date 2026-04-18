import 'package:gasosa_app/domain/entities/vehicle.dart';

/// Contrato para operações remotas de Vehicle (Firestore)
abstract interface class VehicleRemoteDatasource {
  Future<List<Map<String, dynamic>>> getAllByUserId(String userId);
  Future<void> upsert(String userId, VehicleEntity vehicle);
  Future<void> upsertBatch(String userId, List<VehicleEntity> vehicles);
  Future<void> softDelete(String userId, String vehicleId, DateTime deletedAt);
  Future<void> hardDeleteAll(String userId);
}

import 'package:gasosa_app/domain/entities/refuel.dart';

/// Contrato para operações remotas de Refuel (Firestore)
abstract interface class RefuelRemoteDatasource {
  Future<List<Map<String, dynamic>>> getAllByUserId(String userId);
  Future<void> upsert(String userId, RefuelEntity refuel);
  Future<void> upsertBatch(String userId, List<RefuelEntity> refuels);
  Future<void> softDelete(String userId, String refuelId, DateTime deletedAt);
  Future<void> hardDeleteAll(String userId);
}

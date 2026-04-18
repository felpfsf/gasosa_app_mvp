import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gasosa_app/data/remote/vehicle_remote_datasource.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: VehicleRemoteDatasource)
class FirestoreVehicleDatasource implements VehicleRemoteDatasource {
  FirestoreVehicleDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('vehicles');

  @override
  Future<List<Map<String, dynamic>>> getAllByUserId(String userId) async {
    final snapshot = await _collection(userId).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  @override
  Future<void> upsert(String userId, VehicleEntity vehicle) async {
    await _collection(userId)
        .doc(vehicle.id)
        .set(
          _toFirestore(vehicle),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> upsertBatch(String userId, List<VehicleEntity> vehicles) async {
    final batch = _firestore.batch();
    for (final vehicle in vehicles) {
      batch.set(
        _collection(userId).doc(vehicle.id),
        _toFirestore(vehicle),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> softDelete(String userId, String vehicleId, DateTime deletedAt) async {
    await _collection(userId).doc(vehicleId).update({
      'deletedAt': Timestamp.fromDate(deletedAt),
      'updatedAt': Timestamp.fromDate(deletedAt),
    });
  }

  @override
  Future<void> hardDeleteAll(String userId) async {
    final snapshot = await _collection(userId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Map<String, dynamic> _toFirestore(VehicleEntity e) => {
    'name': e.name,
    'plate': e.plate,
    'tankCapacity': e.tankCapacity,
    'fuelType': e.fuelType.name,
    'photoPath': e.photoPath,
    'createdAt': Timestamp.fromDate(e.createdAt),
    'updatedAt': e.updatedAt != null ? Timestamp.fromDate(e.updatedAt!) : null,
  };
}

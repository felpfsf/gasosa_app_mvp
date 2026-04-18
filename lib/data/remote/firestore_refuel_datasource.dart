import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gasosa_app/data/remote/refuel_remote_datasource.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: RefuelRemoteDatasource)
class FirestoreRefuelDatasource implements RefuelRemoteDatasource {
  FirestoreRefuelDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('refuels');

  @override
  Future<List<Map<String, dynamic>>> getAllByUserId(String userId) async {
    final snapshot = await _collection(userId).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  @override
  Future<void> upsert(String userId, RefuelEntity refuel) async {
    await _collection(userId)
        .doc(refuel.id)
        .set(
          _toFirestore(refuel),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> upsertBatch(String userId, List<RefuelEntity> refuels) async {
    final batch = _firestore.batch();
    for (final refuel in refuels) {
      batch.set(
        _collection(userId).doc(refuel.id),
        _toFirestore(refuel),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> softDelete(String userId, String refuelId, DateTime deletedAt) async {
    await _collection(userId).doc(refuelId).update({
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

  static Map<String, dynamic> _toFirestore(RefuelEntity e) => {
    'vehicleId': e.vehicleId,
    'refuelDate': Timestamp.fromDate(e.refuelDate),
    'fuelType': e.fuelType.name,
    'totalValue': e.totalValue,
    'mileage': e.mileage,
    'liters': e.liters,
    'coldStartLiters': e.coldStartLiters,
    'coldStartValue': e.coldStartValue,
    'receiptPath': e.receiptPath,
    'createdAt': Timestamp.fromDate(e.createdAt),
    'updatedAt': e.updatedAt != null ? Timestamp.fromDate(e.updatedAt!) : null,
  };
}

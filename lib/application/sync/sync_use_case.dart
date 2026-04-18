import 'dart:developer' as dev;

import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/data/local/dao/refuel_dao.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/mappers/refuel_firestore_mapper.dart';
import 'package:gasosa_app/data/mappers/refuel_mapper.dart';
import 'package:gasosa_app/data/mappers/vehicle_firestore_mapper.dart';
import 'package:gasosa_app/data/mappers/vehicle_mapper.dart';
import 'package:gasosa_app/data/remote/refuel_remote_datasource.dart';
import 'package:gasosa_app/data/remote/vehicle_remote_datasource.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

class SyncResult {
  const SyncResult({
    this.vehiclesPushed = 0,
    this.vehiclesPulled = 0,
    this.refuelsPushed = 0,
    this.refuelsPulled = 0,
  });

  final int vehiclesPushed;
  final int vehiclesPulled;
  final int refuelsPushed;
  final int refuelsPulled;

  int get total => vehiclesPushed + vehiclesPulled + refuelsPushed + refuelsPulled;
}

@lazySingleton
class SyncUseCase {
  SyncUseCase({
    required VehicleDao vehicleDao,
    required RefuelDao refuelDao,
    required VehicleRemoteDatasource vehicleRemote,
    required RefuelRemoteDatasource refuelRemote,
    required AuthService auth,
    required ObservabilityService observability,
  }) : _vehicleDao = vehicleDao,
       _refuelDao = refuelDao,
       _vehicleRemote = vehicleRemote,
       _refuelRemote = refuelRemote,
       _auth = auth,
       _observability = observability;

  final VehicleDao _vehicleDao;
  final RefuelDao _refuelDao;
  final VehicleRemoteDatasource _vehicleRemote;
  final RefuelRemoteDatasource _refuelRemote;
  final AuthService _auth;
  final ObservabilityService _observability;

  Future<Either<Failure, SyncResult>> call() async {
    dev.log('[Sync] starting...', name: 'sync');
    try {
      final user = await _auth.currentUser();
      if (user == null) {
        dev.log('[Sync] aborted: no user', name: 'sync');
        return left(const ValidationFailure('Usuário não autenticado'));
      }

      final userId = user.id;
      dev.log('[Sync] user=$userId', name: 'sync');

      final vehicleResult = await _syncVehicles(userId);
      final refuelResult = await _syncRefuels(userId);

      final result = SyncResult(
        vehiclesPushed: vehicleResult.$1,
        vehiclesPulled: vehicleResult.$2,
        refuelsPushed: refuelResult.$1,
        refuelsPulled: refuelResult.$2,
      );

      await _observability.logEvent(
        'sync_completed',
        parameters: {
          'vehicles_pushed': result.vehiclesPushed,
          'vehicles_pulled': result.vehiclesPulled,
          'refuels_pushed': result.refuelsPushed,
          'refuels_pulled': result.refuelsPulled,
          'total': result.total,
        },
      );

      dev.log(
        '[Sync] done: vPush=${result.vehiclesPushed} vPull=${result.vehiclesPulled} '
        'rPush=${result.refuelsPushed} rPull=${result.refuelsPulled}',
        name: 'sync',
      );

      return right(result);
    } catch (e, st) {
      dev.log('[Sync] FAILED: $e', name: 'sync', error: e, stackTrace: st);
      await _observability.logError(
        UnexpectedFailure('Sync falhou', e, st),
        stackTrace: st,
        context: {'source': 'SyncUseCase'},
      );
      return left(UnexpectedFailure('Erro durante sincronização', e, st));
    }
  }

  /// Retorna (pushed, pulled)
  Future<(int, int)> _syncVehicles(String userId) async {
    final localRows = await _vehicleDao.getAllByUserIdIncludingDeleted(userId);
    final remoteMaps = await _vehicleRemote.getAllByUserId(userId);
    dev.log('[Sync] vehicles: local=${localRows.length} remote=${remoteMaps.length}', name: 'sync');

    final localById = {for (final r in localRows) r.id: r};
    final remoteById = {for (final m in remoteMaps) m['id'] as String: m};

    final allIds = {...localById.keys, ...remoteById.keys};

    var pushed = 0;
    var pulled = 0;

    for (final id in allIds) {
      final local = localById[id];
      final remote = remoteById[id];

      if (local != null && remote == null) {
        // Só existe local → push para remote
        final entity = VehicleMapper.toDomain(local);
        if (local.deletedAt != null) {
          await _vehicleRemote.softDelete(userId, id, local.deletedAt!);
        } else {
          await _vehicleRemote.upsert(userId, entity);
        }
        pushed++;
      } else if (local == null && remote != null) {
        // Só existe remote → pull para local
        final entity = VehicleFirestoreMapper.fromFirestore(remote, userId);
        final deletedAt = VehicleFirestoreMapper.deletedAtFromFirestore(remote);
        await _vehicleDao.upsert(VehicleMapper.toCompanionWithDeletedAt(entity, deletedAt));
        pulled++;
      } else if (local != null && remote != null) {
        // Existe em ambos → last-write-wins por updatedAt
        final localUpdated = local.updatedAt ?? local.createdAt;
        final remoteEntity = VehicleFirestoreMapper.fromFirestore(remote, userId);
        final remoteUpdated = remoteEntity.updatedAt ?? remoteEntity.createdAt;

        if (localUpdated.isAfter(remoteUpdated)) {
          // Local é mais recente → push
          final entity = VehicleMapper.toDomain(local);
          if (local.deletedAt != null) {
            await _vehicleRemote.softDelete(userId, id, local.deletedAt!);
          } else {
            await _vehicleRemote.upsert(userId, entity);
          }
          pushed++;
        } else if (remoteUpdated.isAfter(localUpdated)) {
          // Remote é mais recente → pull
          final deletedAt = VehicleFirestoreMapper.deletedAtFromFirestore(remote);
          await _vehicleDao.upsert(VehicleMapper.toCompanionWithDeletedAt(remoteEntity, deletedAt));
          pulled++;
        }
        // Se iguais → nenhuma ação necessária
      }
    }

    return (pushed, pulled);
  }

  /// Retorna (pushed, pulled)
  Future<(int, int)> _syncRefuels(String userId) async {
    // Busca todos os vehicle IDs do usuário (incluindo deletados) para buscar refuels locais
    final vehicleRows = await _vehicleDao.getAllByUserIdIncludingDeleted(userId);
    final vehicleIds = vehicleRows.map((v) => v.id).toList();

    final localRows = await _refuelDao.getAllByVehicleIdsIncludingDeleted(vehicleIds);
    final remoteMaps = await _refuelRemote.getAllByUserId(userId);
    dev.log('[Sync] refuels: local=${localRows.length} remote=${remoteMaps.length}', name: 'sync');

    final localById = {for (final r in localRows) r.id: r};
    final remoteById = {for (final m in remoteMaps) m['id'] as String: m};

    final allIds = {...localById.keys, ...remoteById.keys};

    var pushed = 0;
    var pulled = 0;

    for (final id in allIds) {
      final local = localById[id];
      final remote = remoteById[id];

      if (local != null && remote == null) {
        final entity = RefuelMapper.toDomain(local);
        if (local.deletedAt != null) {
          await _refuelRemote.softDelete(userId, id, local.deletedAt!);
        } else {
          await _refuelRemote.upsert(userId, entity);
        }
        pushed++;
      } else if (local == null && remote != null) {
        final entity = RefuelFirestoreMapper.fromFirestore(remote);
        final deletedAt = RefuelFirestoreMapper.deletedAtFromFirestore(remote);
        await _refuelDao.upsert(RefuelMapper.toCompanionWithDeletedAt(entity, deletedAt));
        pulled++;
      } else if (local != null && remote != null) {
        final localUpdated = local.updatedAt ?? local.createdAt;
        final remoteEntity = RefuelFirestoreMapper.fromFirestore(remote);
        final remoteUpdated = remoteEntity.updatedAt ?? remoteEntity.createdAt;

        if (localUpdated.isAfter(remoteUpdated)) {
          final entity = RefuelMapper.toDomain(local);
          if (local.deletedAt != null) {
            await _refuelRemote.softDelete(userId, id, local.deletedAt!);
          } else {
            await _refuelRemote.upsert(userId, entity);
          }
          pushed++;
        } else if (remoteUpdated.isAfter(localUpdated)) {
          final deletedAt = RefuelFirestoreMapper.deletedAtFromFirestore(remote);
          await _refuelDao.upsert(RefuelMapper.toCompanionWithDeletedAt(remoteEntity, deletedAt));
          pulled++;
        }
      }
    }

    return (pushed, pulled);
  }
}

import 'dart:async';
import 'dart:developer' as dev;

import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/data/local/dao/refuel_dao.dart';
import 'package:gasosa_app/data/mappers/refuel_mapper.dart';
import 'package:gasosa_app/data/remote/refuel_remote_datasource.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: RefuelRepository)
class RefuelRepositoryImpl implements RefuelRepository {
  RefuelRepositoryImpl(
    RefuelDao dao,
    this._remote,
    this._auth,
    this._observability,
  ) : _dao = dao;

  final RefuelDao _dao;
  final RefuelRemoteDatasource _remote;
  final AuthService _auth;
  final ObservabilityService _observability;

  @override
  Future<Either<Failure, Unit>> upsertRefuel(RefuelEntity refuel) async {
    try {
      await _dao.upsert(RefuelMapper.toCompanion(refuel));
      _pushRemote((userId) => _remote.upsert(userId, refuel));
      return right(unit);
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao salvar reabastecimento', e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRefuel(String id) async {
    try {
      final row = await _dao.getById(id);
      await _dao.softDeleteById(id);
      if (row != null) {
        _pushRemote((userId) => _remote.softDelete(userId, id, DateTime.now()));
      }
      return right(unit);
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao deletar reabastecimento', e, st));
    }
  }

  @override
  Future<Either<Failure, List<RefuelEntity>>> getAllByVehicleId(String vehicleId) async {
    try {
      final refuels = await _dao.getAllByVehicleId(vehicleId);
      return right(refuels.map(RefuelMapper.toDomain).toList());
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao buscar reabastecimentos', e, st));
    }
  }

  @override
  Future<Either<Failure, RefuelEntity?>> getRefuelById(String id) async {
    try {
      final row = await _dao.getById(id);
      return right(row == null ? null : RefuelMapper.toDomain(row));
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao buscar reabastecimento', e, st));
    }
  }

  @override
  Stream<Either<Failure, List<RefuelEntity>>> watchAllByVehicleId(String vehicleId) {
    return _dao
        .watchByVehicleId(vehicleId)
        .map((rows) => right<Failure, List<RefuelEntity>>(rows.map(RefuelMapper.toDomain).toList()))
        .handleError(
          (Object e, StackTrace st) =>
              left<Failure, List<RefuelEntity>>(DatabaseFailure('Stream reabastecimentos falhou', e, st)),
        );
  }

  @override
  Future<Either<Failure, RefuelEntity?>> getPreviousByVehicleId(
    String vehicleId, {
    required DateTime createdAt,
    required int mileage,
  }) async {
    try {
      final byMileage = await _dao.getPreviousByMileage(vehicleId, mileage: mileage);
      final row = byMileage ?? await _dao.getPreviousByDate(vehicleId, createdAt: createdAt);
      return right(row == null ? null : RefuelMapper.toDomain(row));
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao buscar reabastecimento anterior', e, st));
    }
  }

  void _pushRemote(Future<void> Function(String userId) action) {
    unawaited(
      _auth
          .currentUser()
          .then((user) async {
            if (user == null) {
              dev.log('[RefuelRepo] push skipped: no user', name: 'sync');
              return;
            }
            dev.log('[RefuelRepo] push start for user=${user.id}', name: 'sync');
            await action(user.id);
            dev.log('[RefuelRepo] push OK', name: 'sync');
          })
          .catchError((Object e, StackTrace st) {
            dev.log('[RefuelRepo] push FAILED: $e', name: 'sync', error: e, stackTrace: st);
            _observability.logError(
              UnexpectedFailure('Sync push refuel falhou', e, st),
              stackTrace: st,
              context: {'source': 'RefuelRepositoryImpl'},
            );
          }),
    );
  }
}

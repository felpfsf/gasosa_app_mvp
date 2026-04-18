import 'dart:async';
import 'dart:developer' as dev;

import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/mappers/vehicle_mapper.dart';
import 'package:gasosa_app/data/remote/vehicle_remote_datasource.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: VehicleRepository)
class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(
    VehicleDao dao,
    this._remote,
    this._auth,
    this._observability,
  ) : _dao = dao;

  final VehicleDao _dao;
  final VehicleRemoteDatasource _remote;
  final AuthService _auth;
  final ObservabilityService _observability;

  @override
  Future<Either<Failure, Unit>> upsertVehicle(VehicleEntity vehicle) async {
    try {
      await _dao.upsert(VehicleMapper.toCompanion(vehicle));
      _pushRemote(() => _remote.upsert(vehicle.userId, vehicle));
      return right(unit);
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao salvar veículo', e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteVehicle(String id) async {
    try {
      final row = await _dao.getById(id);
      await _dao.softDeleteById(id);
      if (row != null) {
        _pushRemote(() => _remote.softDelete(row.userId, id, DateTime.now()));
      }
      return right(unit);
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao deletar veículo', e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAllByUserId(String userId) async {
    try {
      await _dao.hardDeleteAllByUserId(userId);
      _pushRemote(() => _remote.hardDeleteAll(userId));
      return right(unit);
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao deletar dados do usuário', e, st));
    }
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getAllByUserId(String userId) async {
    try {
      final rows = await _dao.getAllByUserId(userId);
      return right(rows.map(VehicleMapper.toDomain).toList());
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao listar veículos', e, st));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity?>> getVehicleById(String id) async {
    try {
      final row = await _dao.getById(id);
      return right(row == null ? null : VehicleMapper.toDomain(row));
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao buscar veículo', e, st));
    }
  }

  @override
  Stream<Either<Failure, List<VehicleEntity>>> watchAllByUserId(String userId) {
    return _dao
        .watchAllByUserId(userId)
        .map((rows) => right<Failure, List<VehicleEntity>>(rows.map(VehicleMapper.toDomain).toList()))
        .handleError(
          (Object e, StackTrace st) =>
              left<Failure, List<VehicleEntity>>(DatabaseFailure('Stream veículos falhou', e, st)),
        );
  }

  void _pushRemote(Future<void> Function() action) {
    unawaited(
      _auth
          .currentUser()
          .then((user) async {
            if (user == null) {
              dev.log('[VehicleRepo] push skipped: no user', name: 'sync');
              return;
            }
            dev.log('[VehicleRepo] push start for user=${user.id}', name: 'sync');
            await action();
            dev.log('[VehicleRepo] push OK', name: 'sync');
          })
          .catchError((Object e, StackTrace st) {
            dev.log('[VehicleRepo] push FAILED: $e', name: 'sync', error: e, stackTrace: st);
            _observability.logError(
              UnexpectedFailure('Sync push vehicle falhou', e, st),
              stackTrace: st,
              context: {'source': 'VehicleRepositoryImpl'},
            );
          }),
    );
  }
}

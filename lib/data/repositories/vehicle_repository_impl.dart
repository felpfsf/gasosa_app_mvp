import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/mappers/vehicle_mapper.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(VehicleDao dao) : _dao = dao;

  final VehicleDao _dao;

  @override
  Future<Either<Failure, Unit>> createVehicle(VehicleEntity vehicle) async {
    try {
      await _dao.upsert(VehicleMapper.toCompanion(vehicle));
      return right(unit);
    } catch (e) {
      return left(DatabaseFailure('Erro ao salvar veículo', cause: e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteVehicle(String id) async {
    try {
      await _dao.deleteById(id);
      return right(unit);
    } catch (e) {
      return left(DatabaseFailure('Erro ao deletar veículo', cause: e));
    }
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getAllByUserId(String userId) async {
    try {
      final rows = await _dao.getAllByUserId(userId);
      return right(rows.map(VehicleMapper.toDomain).toList());
    } catch (e) {
      return left(DatabaseFailure('Erro ao listar veículos', cause: e));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity?>> getVehicleById(String id) async {
    try {
      final row = await _dao.getById(id);
      return right(row == null ? null : VehicleMapper.toDomain(row));
    } catch (e) {
      return left(DatabaseFailure('Erro ao buscar veículo', cause: e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateVehicle(VehicleEntity vehicle) async {
    try {
      await _dao.upsert(VehicleMapper.toCompanion(vehicle));
      return right(unit);
    } catch (e) {
      return left(DatabaseFailure('Erro ao atualizar veículo', cause: e));
    }
  }

  @override
  Stream<Either<Failure, List<VehicleEntity>>> watchAllByUserId(String userId) {
    return _dao
        .watchAllByUserId(userId)
        .map(
          (rows) => right<Failure, List<VehicleEntity>>(rows.map(VehicleMapper.toDomain).toList()),
        )
        .handleError((e) {
          return Stream.value(left<Failure, List<VehicleEntity>>(DatabaseFailure('Stream vehicles falhou: $e')));
        });
  }
}

import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/data/local/dao/refuel_dao.dart';
import 'package:gasosa_app/data/mappers/refuel_mapper.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: RefuelRepository)
class RefuelRepositoryImpl implements RefuelRepository {
  RefuelRepositoryImpl(RefuelDao dao) : _dao = dao;

  final RefuelDao _dao;

  @override
  Future<Either<Failure, Unit>> upsertRefuel(RefuelEntity refuel) async {
    try {
      await _dao.upsert(RefuelMapper.toCompanion(refuel));
      return right(unit);
    } catch (e, st) {
      return left(DatabaseFailure('Erro ao salvar reabastecimento', e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRefuel(String id) async {
    try {
      await _dao.deleteById(id);
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
}

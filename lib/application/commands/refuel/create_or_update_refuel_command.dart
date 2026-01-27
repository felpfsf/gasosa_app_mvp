import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';

class CreateOrUpdateRefuelCommand {
  CreateOrUpdateRefuelCommand({required RefuelRepository repository}) : _repository = repository;

  final RefuelRepository _repository;

  Future<Either<Failure, Unit>> call(RefuelEntity entity) async {
    return _repository.upsertRefuel(entity);
  }
}

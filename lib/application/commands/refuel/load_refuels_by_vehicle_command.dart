import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';

class LoadRefuelsByVehicleCommand {
  LoadRefuelsByVehicleCommand({required RefuelRepository repository}) : _repository = repository;

  final RefuelRepository _repository;

  Stream<Either<Failure, List<RefuelEntity>>> call(String vehicleId) => _repository.watchAllByVehicleId(vehicleId);
}

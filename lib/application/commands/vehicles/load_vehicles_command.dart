import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';

class LoadVehiclesCommand {
  LoadVehiclesCommand(this._repository);
  final VehicleRepository _repository;

  Stream<Either<Failure, List<VehicleEntity>>> watchAllByUserId(String userId) => _repository.watchAllByUserId(userId);
}

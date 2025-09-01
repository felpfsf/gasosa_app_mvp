import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';

class CreateOrUpdateVehicleCommand {
  CreateOrUpdateVehicleCommand({required VehicleRepository repository}) : _repository = repository;

  final VehicleRepository _repository;

  Future<Either<Failure, Unit>> call(VehicleEntity entity) async {
    return entity.id.isEmpty ? _repository.createVehicle(entity) : _repository.updateVehicle(entity);
  }
}

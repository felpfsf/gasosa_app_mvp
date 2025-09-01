import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';

class DeleteVehicleCommand {
  DeleteVehicleCommand({required VehicleRepository repository}) : _repository = repository;

  final VehicleRepository _repository;

  Future<Either<Failure, Unit>> call(String vehicleId) async => _repository.deleteVehicle(vehicleId);
}

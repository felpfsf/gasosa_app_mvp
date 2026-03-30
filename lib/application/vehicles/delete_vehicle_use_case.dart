import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteVehicleUseCase {
  DeleteVehicleUseCase({required VehicleRepository repository}) : _repository = repository;

  final VehicleRepository _repository;

  Future<Either<Failure, Unit>> call(String vehicleId) async => _repository.deleteVehicle(vehicleId);
}

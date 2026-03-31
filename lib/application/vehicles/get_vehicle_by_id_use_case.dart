import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetVehicleByIdUseCase {
  GetVehicleByIdUseCase({required VehicleRepository repository}) : _repository = repository;

  final VehicleRepository _repository;

  Future<Either<Failure, VehicleEntity?>> call(String id) => _repository.getVehicleById(id);
}

import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoadVehiclesUseCase {
  LoadVehiclesUseCase({required VehicleRepository repository}) : _repository = repository;

  final VehicleRepository _repository;

  Stream<Either<Failure, List<VehicleEntity>>> watchAllByUserId(String userId) => _repository.watchAllByUserId(userId);
}

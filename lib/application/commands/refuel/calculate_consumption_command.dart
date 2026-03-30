import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class CalculateConsumptionCommand {
  CalculateConsumptionCommand({required RefuelRepository repository}) : _repository = repository;

  final RefuelRepository _repository;

  Future<Either<Failure, RefuelEntity?>> call(String vehicleId, DateTime createdAt, int mileage) async {
    return _repository.getPreviousByVehicleId(vehicleId, createdAt: createdAt, mileage: mileage);
  }
}

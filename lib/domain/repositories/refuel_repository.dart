import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';

abstract interface class RefuelRepository {
  Future<Either<Failure, Unit>> addRefuel(RefuelEntity refuel);
  Future<Either<Failure, Unit>> updateRefuel(RefuelEntity refuel);
  Future<Either<Failure, RefuelEntity?>> getRefuelById(String id);
  Future<Either<Failure, List<RefuelEntity>>> getAllByVehicleId(String vehicleId);
  Stream<Either<Failure, List<RefuelEntity>>> watchAllByVehicleId(String vehicleId);
  Future<Either<Failure, Unit>> deleteRefuel(String id);
  Future<Either<Failure, RefuelEntity?>> getPreviousByVehicleId(
    String vehicleId, {
    required DateTime createdAt,
    required int mileage,
  });
}

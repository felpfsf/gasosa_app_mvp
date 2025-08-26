import 'package:dartz/dartz.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';

abstract interface class VehicleRepository {
  Future<Either<Failure, Unit>> createVehicle(VehicleEntity vehicle);
  Future<Either<Failure, VehicleEntity?>> getVehicleById(String id);
  Future<Either<Failure, List<VehicleEntity>>> getAllByUserId(String userId);
  Stream<Either<Failure, List<VehicleEntity>>> watchAllByUserId(String userId);
  Future<Either<Failure, Unit>> updateVehicle(VehicleEntity vehicle);
  Future<Either<Failure, Unit>> deleteVehicle(String id);
}

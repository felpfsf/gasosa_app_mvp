import 'package:flutter/foundation.dart';
import 'package:gasosa_app/application/refuel/get_refuels_by_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/delete_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/get_vehicle_by_id_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:injectable/injectable.dart';

@injectable
class VehicleDetailViewModel {
  VehicleDetailViewModel(
    this._getVehicleById,
    this._delete,
    this._getRefuels,
  ) : loadCommand = Command<Unit>(),
      deleteCommand = Command<Unit>();

  final GetVehicleByIdUseCase _getVehicleById;
  final DeleteVehicleUseCase _delete;
  final GetRefuelsByVehicleUseCase _getRefuels;

  final Command<Unit> loadCommand;
  final Command<Unit> deleteCommand;

  final ValueNotifier<VehicleEntity?> vehicle = ValueNotifier(null);
  final ValueNotifier<List<RefuelEntity>> refuels = ValueNotifier([]);

  Future<void> init(String vehicleId) async {
    await loadCommand.run(() async {
      final (vehicleResult, refuelsResult) = await (
        _getVehicleById(vehicleId),
        _getRefuels(vehicleId),
      ).wait;

      return vehicleResult.flatMap((v) {
        if (v == null) {
          return const Left(ValidationFailure('Veículo não encontrado'));
        }
        return refuelsResult
            .map((r) {
              final sorted = List<RefuelEntity>.from(r)..sort((a, b) => b.refuelDate.compareTo(a.refuelDate));
              return (vehicle: v, refuels: sorted);
            })
            .map((data) {
              vehicle.value = data.vehicle;
              refuels.value = data.refuels;
              return unit;
            });
      });
    });
  }

  Future<Either<Failure, Unit>?> deleteVehicle(String vehicleId) => deleteCommand.run(() => _delete(vehicleId));

  void dispose() {
    loadCommand.dispose();
    deleteCommand.dispose();
    vehicle.dispose();
    refuels.dispose();
  }
}

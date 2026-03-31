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
  ) : loadCommand = Command<void>(),
      deleteCommand = Command<void>();

  final GetVehicleByIdUseCase _getVehicleById;
  final DeleteVehicleUseCase _delete;
  final GetRefuelsByVehicleUseCase _getRefuels;

  final Command<void> loadCommand;
  final Command<void> deleteCommand;

  final ValueNotifier<VehicleEntity?> vehicle = ValueNotifier(null);
  final ValueNotifier<List<RefuelEntity>> refuels = ValueNotifier([]);

  Future<void> init(String vehicleId) async {
    await loadCommand.run(() async {
      final results = await Future.wait([
        _getVehicleById(vehicleId),
        _getRefuels(vehicleId),
      ]);

      final vehicleResult = results[0] as Either<Failure, VehicleEntity?>;
      final refuelsResult = results[1] as Either<Failure, List<RefuelEntity>>;

      return vehicleResult.flatMap((v) {
        if (v == null) {
          return const Left(ValidationFailure('Veículo não encontrado'));
        }
        return refuelsResult.map((r) {
          final sorted = List<RefuelEntity>.from(r)..sort((a, b) => b.refuelDate.compareTo(a.refuelDate));
          vehicle.value = v;
          refuels.value = sorted;
        });
      });
    });
  }

  Future<void> deleteVehicle(String vehicleId) => deleteCommand.run(() => _delete(vehicleId));

  void dispose() {
    loadCommand.dispose();
    deleteCommand.dispose();
    vehicle.dispose();
    refuels.dispose();
  }
}

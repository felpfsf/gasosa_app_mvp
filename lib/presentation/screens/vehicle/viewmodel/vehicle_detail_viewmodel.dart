import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:gasosa_app/application/refuel/get_refuels_by_vehicle_use_case.dart';
import 'package:gasosa_app/application/sync/sync_use_case.dart';
import 'package:gasosa_app/application/vehicles/delete_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/get_vehicle_by_id_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:injectable/injectable.dart';

@injectable
class VehicleDetailViewModel {
  VehicleDetailViewModel(
    this._getVehicleById,
    this._delete,
    this._getRefuels,
    this._sync,
  ) : loadCommand = Command<Unit>(),
      deleteCommand = Command<Unit>();

  final GetVehicleByIdUseCase _getVehicleById;
  final DeleteVehicleUseCase _delete;
  final GetRefuelsByVehicleUseCase _getRefuels;
  final SyncUseCase _sync;

  final Command<Unit> loadCommand;
  final Command<Unit> deleteCommand;

  final ValueNotifier<VehicleEntity?> _vehicle = ValueNotifier(null);
  final ValueNotifier<List<RefuelEntity>> _refuels = ValueNotifier([]);

  ValueListenable<VehicleEntity?> get vehicle => _vehicle;
  ValueListenable<List<RefuelEntity>> get refuels => _refuels;

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
              _vehicle.value = data.vehicle;
              _refuels.value = data.refuels;
              return unit;
            });
      });
    });
  }

  Future<Either<Failure, Unit>?> deleteVehicle(String vehicleId) => deleteCommand.run(() => _delete(vehicleId));

  Future<void> refresh(String vehicleId) async {
    dev.log('[VehicleDetail] pull-to-refresh: syncing...', name: 'sync');
    try {
      final result = await _sync();
      result.fold(
        (f) => dev.log('[VehicleDetail] refresh sync failed: $f', name: 'sync'),
        (r) => dev.log('[VehicleDetail] refresh sync ok: total=${r.total}', name: 'sync'),
      );
    } catch (e, st) {
      dev.log('[VehicleDetail] refresh sync error: $e', name: 'sync', error: e, stackTrace: st);
    }
    await init(vehicleId);
  }

  String get vehicleName => _vehicle.value?.name ?? '';
  String get vehiclePhotoPath => _vehicle.value?.photoPath ?? '';
  String get fuelTypeLabel => _vehicle.value?.fuelType.displayName ?? '';

  String get vehicleSubtitle {
    final v = _vehicle.value;
    if (v == null) return '';
    final plate = (v.plate ?? '').toUpperCase();
    final cap = v.tankCapacity?.toStringAsFixed(0) ?? 'N/A';
    final capLabel = 'Capacidade do tanque: $cap${v.tankCapacity != null ? ' L' : ''}';
    return [if (plate.isNotEmpty) 'Placa: $plate', capLabel].join(' • ');
  }

  void dispose() {
    loadCommand.dispose();
    deleteCommand.dispose();
    _vehicle.dispose();
    _refuels.dispose();
  }
}

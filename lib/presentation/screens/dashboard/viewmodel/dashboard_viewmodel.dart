import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gasosa_app/application/vehicles/delete_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/load_vehicles_use_case.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/core/presentation/stream_command.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:injectable/injectable.dart';

@injectable
class DashboardViewModel {
  DashboardViewModel(
    this._loadVehicles,
    this._deleteVehicle,
  ) : watchVehicles = StreamCommand<List<VehicleEntity>>(),
      deleteCommand = Command<void>();

  final LoadVehiclesUseCase _loadVehicles;
  final DeleteVehicleUseCase _deleteVehicle;

  final StreamCommand<List<VehicleEntity>> watchVehicles;
  final Command<void> deleteCommand;

  void init() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      watchVehicles.state.value = const UiError(ValidationFailure('Usuário não autenticado'));
      return;
    }

    watchVehicles.watch(
      () => _loadVehicles
          .watchAllByUserId(uid)
          .transform(
            StreamTransformer.fromHandlers(
              handleData: (either, sink) => either.fold(
                (f) => sink.addError(f),
                (v) => sink.add(v),
              ),
            ),
          ),
      keepLastData: true,
    );
  }

  Future<void> deleteVehicle(String vehicleId) => deleteCommand.run(() => _deleteVehicle(vehicleId));

  void retry() => init();

  void dispose() {
    watchVehicles.dispose();
    deleteCommand.dispose();
  }
}

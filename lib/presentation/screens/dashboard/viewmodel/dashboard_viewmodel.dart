import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gasosa_app/application/vehicles/delete_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/load_vehicles_use_case.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/core/presentation/stream_command.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class DashboardViewModel {
  DashboardViewModel(
    this._auth,
    this._loadVehicles,
    this._deleteVehicle,
  ) : watchVehicles = StreamCommand<List<VehicleEntity>>(),
      deleteCommand = Command<void>();

  final AuthService _auth;
  final LoadVehiclesUseCase _loadVehicles;
  final DeleteVehicleUseCase _deleteVehicle;

  final StreamCommand<List<VehicleEntity>> watchVehicles;
  final Command<void> deleteCommand;
  final ValueNotifier<AuthUser?> currentUser = ValueNotifier(null);

  Future<void> init() async {
    currentUser.value = await _auth.currentUser();
    final uid = currentUser.value?.id;
    if (uid == null || uid.isEmpty) {
      watchVehicles.state.value = const UiError(ValidationFailure('Usuário não autenticado'));
      return;
    }

    watchVehicles.watch(
      () => _loadVehicles(uid).transform(
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

  Future<void> logout() => _auth.logout();

  void retry() => init();

  void dispose() {
    watchVehicles.dispose();
    deleteCommand.dispose();
    currentUser.dispose();
  }
}

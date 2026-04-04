import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gasosa_app/application/auth/logout_use_case.dart';
import 'package:gasosa_app/application/vehicles/load_vehicles_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
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
    this._logout,
  ) : watchVehicles = StreamCommand<List<VehicleEntity>>();

  final AuthService _auth;
  final LoadVehiclesUseCase _loadVehicles;
  final LogoutUseCase _logout;

  final StreamCommand<List<VehicleEntity>> watchVehicles;
  final ValueNotifier<AuthUser?> _currentUser = ValueNotifier(null);
  ValueListenable<AuthUser?> get currentUser => _currentUser;

  Future<void> init() async {
    _currentUser.value = await _auth.currentUser();
    final uid = _currentUser.value?.id;
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

  Future<Either<Failure, void>> logout() => _logout();

  void retry() => init();

  void dispose() {
    watchVehicles.dispose();
    _currentUser.dispose();
  }
}

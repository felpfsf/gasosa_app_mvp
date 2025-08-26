import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gasosa_app/application/commands/vehicles/load_vehicles_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';

class DashboardState {
  DashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.vehicles = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final List<VehicleEntity> vehicles;

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<VehicleEntity>? vehicles,
  }) => DashboardState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    vehicles: vehicles ?? this.vehicles,
  );
}

class DashboardViewModel extends BaseViewModel {
  DashboardViewModel({
    required LoadVehiclesCommand loadVehicles,
    required LoadingController loading,
  }) : _loadVehicles = loadVehicles,
       super(loading);

  final LoadVehiclesCommand _loadVehicles;

  DashboardState _state = DashboardState();
  DashboardState get state => _state;

  StreamSubscription<Either<Failure, List<VehicleEntity>>>? _sub;

  Future<void> init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      _setError('Usuário não autenticado');
      return;
    }

    _sub = _loadVehicles
        .watchAllByUserId(uid)
        .listen(
          (either) {
            either.fold(
              (failure) => _setError(''),
              (vehicles) {
                _state = _state.copyWith(
                  isLoading: false,
                  vehicles: vehicles,
                );
                notifyListeners();
              },
            );
          },
          onError: (err, stack) {
            _setError('Erro ao carregar veículos $err: $stack');
          },
        );
  }

  @override
  void setViewLoading({bool value = false}) {
    _state = DashboardState(isLoading: value);
    notifyListeners();
  }

  void _setError(String message) {
    _state = DashboardState(errorMessage: message);
    notifyListeners();
  }

  Future<void> retry() async {
    await _sub?.cancel();
    _sub = null;
    await init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

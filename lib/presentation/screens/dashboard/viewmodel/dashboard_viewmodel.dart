import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gasosa_app/application/commands/vehicles/delete_vehicle_command.dart';
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
    bool clearError = false,
    List<VehicleEntity>? vehicles,
  }) => DashboardState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    vehicles: vehicles ?? this.vehicles,
  );
}

class DashboardViewModel extends BaseViewModel {
  DashboardViewModel({
    required LoadVehiclesCommand loadVehicles,
    required LoadingController loading,
    required DeleteVehicleCommand deleteVehicle,
  }) : _loadVehicles = loadVehicles,
       _deleteVehicle = deleteVehicle,
       super(loading);

  final LoadVehiclesCommand _loadVehicles;
  final DeleteVehicleCommand _deleteVehicle;

  DashboardState _state = DashboardState();
  DashboardState get state => _state;

  StreamSubscription<Either<Failure, List<VehicleEntity>>>? _sub;
  bool _awaitingFirstEmission = false;
  bool _initialized = false;

  Future<void> init() async {
    // Evita múltiplas inicializações
    if (_initialized) {
      return;
    }
    _initialized = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      _setError('Usuário não autenticado');
      return;
    }
    _awaitingFirstEmission = true;
    setViewLoading(value: true);

    // TODO(felipe): delaying for testing purpose
    await Future.delayed(const Duration(milliseconds: 300));

    _sub = _loadVehicles
        .watchAllByUserId(uid)
        .listen(
          (either) {
            if (_awaitingFirstEmission) {
              _awaitingFirstEmission = false;
              setViewLoading();
            }
            either.fold(
              (failure) {
                _setError('Erro ao carregar veículos: ${failure.message}');
              },
              (vehicles) {
                _state = _state.copyWith(
                  isLoading: false,
                  clearError: true,
                  vehicles: vehicles,
                );
                notifyListeners();
              },
            );
          },
          onError: (err, stack) {
            if (_awaitingFirstEmission) {
              _awaitingFirstEmission = false;
              setViewLoading();
            }
            _setError('Erro ao carregar veículos $err: $stack');
          },
        );
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final response = await track(() => _deleteVehicle.call(vehicleId));
    response.fold(
      (failure) => _setError(failure.message),
      (_) => {},
    );
  }

  @override
  void setViewLoading({bool value = false}) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

  void _setError(String message) {
    _state = _state.copyWith(
      isLoading: false,
      errorMessage: message.isEmpty ? 'Erro inesperado' : message,
    );
    notifyListeners();
  }

  Future<void> retry() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
    await init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

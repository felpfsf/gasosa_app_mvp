import 'package:gasosa_app/application/commands/vehicles/delete_vehicle_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';

class VehicleDetailState {
  VehicleDetailState({
    this.isLoading = false,
    this.errorMessage,
    this.vehicle,
  });

  final bool isLoading;
  final String? errorMessage;
  final VehicleEntity? vehicle;

  VehicleDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    VehicleEntity? vehicle,
  }) {
    return VehicleDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      vehicle: vehicle ?? this.vehicle,
    );
  }
}

class VehicleDetailViewModel extends BaseViewModel {
  VehicleDetailViewModel({
    required VehicleRepository repository,
    required DeleteVehicleCommand delete,
    required LoadingController loading,
  }) : _repository = repository,
       _delete = delete,
       super(loading);

  final VehicleRepository _repository;
  final DeleteVehicleCommand _delete;

  VehicleDetailState _state = VehicleDetailState();
  VehicleDetailState get state => _state;

  Future<void> init(String vehicleId) async {
    setViewLoading(value: true);
    final response = await _repository.getVehicleById(vehicleId);
    /// TODO: delaying for testing purpose
    await Future.delayed(const Duration(milliseconds: 500));
    response.fold(
      (failure) {
        _setError(const BusinessFailure('Erro ao carregar veículo'));
        return;
      },
      (vehicle) {
        _state = _state.copyWith(vehicle: vehicle);
        setViewLoading();
      },
    );
  }

  Future<bool> deleteVehicle() async {
    final vehicle = _state.vehicle;
    if (vehicle == null) return false;
    final response = await track(() => _delete(vehicle.id));
    return response.isRight();
  }

  @override
  void setViewLoading({bool value = false}) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

  void _setError(Failure failure) {
    _state = _state.copyWith(errorMessage: failure.message);
    setViewLoading();
  }
}

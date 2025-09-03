import 'package:dartz/dartz.dart';
import 'package:gasosa_app/application/commands/vehicles/delete_vehicle_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';

class VehicleDetailState {
  VehicleDetailState({
    this.isLoading = false,
    this.errorMessage,
    this.vehicle,
    this.refuels = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final VehicleEntity? vehicle;
  final List<RefuelEntity>? refuels;

  VehicleDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    VehicleEntity? vehicle,
    List<RefuelEntity>? refuels,
  }) {
    return VehicleDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      vehicle: vehicle ?? this.vehicle,
      refuels: refuels ?? this.refuels,
    );
  }
}

class VehicleDetailViewModel extends BaseViewModel {
  VehicleDetailViewModel({
    required VehicleRepository repository,
    required DeleteVehicleCommand delete,
    required LoadingController loading,
    required RefuelRepository refuelRepository,
  }) : _repository = repository,
       _delete = delete,
       _refuelRepository = refuelRepository,
       super(loading);

  final VehicleRepository _repository;
  final RefuelRepository _refuelRepository;
  final DeleteVehicleCommand _delete;

  VehicleDetailState _state = VehicleDetailState();
  VehicleDetailState get state => _state;

  Future<void> init(String vehicleId) async {
    setViewLoading(value: true);
    try {
      final results = await Future.wait([
        _repository.getVehicleById(vehicleId),
        _refuelRepository.getAllByVehicleId(vehicleId),
      ]);

      final vehicleResponse = results[0] as Either<Failure, VehicleEntity?>;
      final refuelsResponse = results[1] as Either<Failure, List<RefuelEntity>>;

      // TODO(felipe): delaying for testing purpose
      await Future.delayed(const Duration(milliseconds: 500));
      vehicleResponse.fold(
        (failure) {
          _setError(const BusinessFailure('Erro ao carregar veículo'));
        },
        (vehicle) {
          _state = _state.copyWith(vehicle: vehicle);
          refuelsResponse.fold(
            (failure) {
              _setError(const BusinessFailure('Erro ao carregar abastecimentos'));
              _state = _state.copyWith(refuels: []);
            },
            (refuels) {
              final sortedRefuels = List<RefuelEntity>.from(refuels)
                ..sort((a, b) => b.refuelDate.compareTo(a.refuelDate));
              _state = _state.copyWith(refuels: sortedRefuels);
            },
          );
        },
      );
    } catch (e) {
      _setError(const BusinessFailure('Erro inesperado ao carregar detalhes do veículo'));
    } finally {
      setViewLoading();
    }
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
    // setViewLoading();
  }
}

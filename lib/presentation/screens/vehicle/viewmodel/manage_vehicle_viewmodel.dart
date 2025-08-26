import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:gasosa_app/application/commands/vehicles/create_or_update_vehicle_command.dart';
import 'package:gasosa_app/application/commands/vehicles/delete_vehicle_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';

class ManageVehicleState {
  const ManageVehicleState({
    this.isLoading = false,
    this.errorMessage,
    this.initial,
    this.name = '',
    this.plate = '',
    this.tankCapacity = '',
    this.photoPath = '',
    this.isEdit = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final VehicleEntity? initial;
  final String name;
  final String plate;
  final String tankCapacity;
  final String? photoPath;
  final bool isEdit;

  ManageVehicleState copyWith({
    bool? isLoading,
    String? errorMessage,
    VehicleEntity? initial,
    String? name,
    String? plate,
    String? tankCapacity,
    String? photoPath,
    bool clearPhotoPath = false,
    bool? isEdit,
  }) {
    return ManageVehicleState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      initial: initial ?? this.initial,
      name: name ?? this.name,
      plate: plate ?? this.plate,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      isEdit: isEdit ?? this.isEdit,
    );
  }
}

class ManageVehicleViewModel extends BaseViewModel {
  ManageVehicleViewModel({
    required CreateOrUpdateVehicleCommand saveVehicle,
    required DeleteVehicleCommand deleteVehicle,
    required VehicleRepository repository,
    required LoadingController loading,
  }) : _saveVehicle = saveVehicle,
       _deleteVehicle = deleteVehicle,
       _repository = repository,
       super(loading);

  final CreateOrUpdateVehicleCommand _saveVehicle;
  final DeleteVehicleCommand _deleteVehicle;
  final VehicleRepository _repository;

  ManageVehicleState _state = const ManageVehicleState();
  ManageVehicleState get state => _state;

  final nameEC = TextEditingController();
  final plateEC = TextEditingController();
  final tankCapacityEC = TextEditingController();

  Future<void> init({String? vehicleId}) async {
    if (vehicleId != null && vehicleId.isNotEmpty) {
      setViewLoading(value: true);
      final either = await _repository.getVehicleById(vehicleId);
      either.fold(
        _setFailure,
        (vehicle) {
          if (vehicle == null) {
            _setFailure(const BusinessFailure('Veículo não encontrado'));
            return;
          }
          _state = _state.copyWith(
            isLoading: false,
            isEdit: true,
            initial: vehicle,
            name: vehicle.name,
            plate: vehicle.plate ?? '',
            tankCapacity: vehicle.tankCapacity?.toString() ?? '',
            photoPath: vehicle.photoPath ?? '',
          );
          nameEC.text = _state.name;
          plateEC.text = _state.plate;
          tankCapacityEC.text = _state.tankCapacity;
          notifyListeners();
        },
      );
    }
  }

  @override
  void setViewLoading({bool value = false}) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

  void _setFailure(Failure failure) {
    _state = _state.copyWith(errorMessage: failure.message);
    notifyListeners();
  }

  void updateName(String value) {
    _state = _state.copyWith(name: value);
    notifyListeners();
  }

  void updatePlate(String value) {
    _state = _state.copyWith(plate: value);
    notifyListeners();
  }

  void updateTankCapacity(String value) {
    _state = _state.copyWith(tankCapacity: value);
    notifyListeners();
  }

  void updatePhotoPath(String? value) {
    _state = _state.copyWith(photoPath: value, clearPhotoPath: value == null);
    notifyListeners();
  }

  double? _parseCapacity(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    return parsed;
  }

  VehicleEntity _buildEntity() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isEdit = state.isEdit && state.initial != null;

    return VehicleEntity(
      id: isEdit ? state.initial!.id : UniqueKey().toString(),
      userId: uid,
      name: state.name.trim(),
      plate: state.plate.trim().isEmpty ? null : state.plate.trim(),
      tankCapacity: _parseCapacity(state.tankCapacity.trim()),
      photoPath: state.photoPath,
      createdAt: isEdit ? state.initial!.createdAt : DateTime.now(),
      updatedAt: isEdit ? DateTime.now() : null,
    );
  }

  Future<Either<Failure, Unit>> save() async {
    final entity = _buildEntity();
    final response = await _saveVehicle(entity);
    response.fold(_setFailure, (_) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    });
    return response;
  }

  Future<Either<Failure, Unit>> delete() async {
    if (!state.isEdit || state.initial == null) {
      const failure = BusinessFailure('Não é possível deletar um veículo que não foi salvo.');
      _setFailure(failure);
      return left(failure);
    }
    final response = await _deleteVehicle(state.initial!.id);
    response.fold(_setFailure, (_) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    });
    return response;
  }

  @override
  void dispose() {
    nameEC.dispose();
    plateEC.dispose();
    tankCapacityEC.dispose();
    super.dispose();
  }
}

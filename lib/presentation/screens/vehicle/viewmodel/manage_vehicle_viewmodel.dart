import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:gasosa_app/application/commands/photos/delete_photo_command.dart';
import 'package:gasosa_app/application/commands/photos/save_photo_command.dart';
import 'package:gasosa_app/application/commands/vehicles/create_or_update_vehicle_command.dart';
import 'package:gasosa_app/application/commands/vehicles/delete_vehicle_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/helpers/uuid.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
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
    this.fuelType = FuelType.flex,
    this.photoPath = '',
    this.isEdit = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final VehicleEntity? initial;
  final String name;
  final String plate;
  final String tankCapacity;
  final FuelType fuelType;
  final String? photoPath;
  final bool isEdit;

  ManageVehicleState copyWith({
    bool? isLoading,
    String? errorMessage,
    VehicleEntity? initial,
    String? name,
    String? plate,
    String? tankCapacity,
    FuelType? fuelType,
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
      fuelType: fuelType ?? this.fuelType,
      isEdit: isEdit ?? this.isEdit,
    );
  }
}

class ManageVehicleViewModel extends BaseViewModel {
  ManageVehicleViewModel({
    required VehicleRepository repository,
    required CreateOrUpdateVehicleCommand saveVehicle,
    required DeleteVehicleCommand deleteVehicle,
    required SavePhotoCommand savePhoto,
    required DeletePhotoCommand deletePhoto,
    required LoadingController loading,
  }) : _saveVehicle = saveVehicle,
       _deleteVehicle = deleteVehicle,
       _repository = repository,
       _savePhoto = savePhoto,
       _deletePhoto = deletePhoto,
       super(loading);

  final VehicleRepository _repository;

  final CreateOrUpdateVehicleCommand _saveVehicle;
  final DeleteVehicleCommand _deleteVehicle;
  final SavePhotoCommand _savePhoto;
  final DeletePhotoCommand _deletePhoto;

  ManageVehicleState _state = const ManageVehicleState();
  ManageVehicleState get state => _state;

  final nameEC = TextEditingController();
  final plateEC = TextEditingController();
  final tankCapacityEC = TextEditingController();
  String? _stagedToDeletePhotoPath;

  FuelType get fuelType => state.fuelType;

  @override
  void setViewLoading({bool value = false}) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

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
            fuelType: vehicle.fuelType,
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

  VehicleEntity _buildEntity() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isEdit = state.isEdit && state.initial != null;

    return VehicleEntity(
      id: isEdit ? state.initial!.id : UuidHelper.generate(),
      userId: uid,
      name: state.name.trim(),
      plate: state.plate.trim().isEmpty ? null : state.plate.trim(),
      tankCapacity: _parseCapacity(state.tankCapacity.trim()),
      fuelType: state.fuelType,
      photoPath: state.photoPath,
      createdAt: isEdit ? state.initial!.createdAt : DateTime.now(),
      updatedAt: isEdit ? DateTime.now() : null,
    );
  }

  double? _parseCapacity(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    return parsed;
  }

  Future<Either<Failure, Unit>> save() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final entity = _buildEntity();
    final response = await _saveVehicle(entity);

    response.fold(_setFailure, (_) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();

      _cleanupStagedPhoto();
    });

    return response;
  }

  Future<Either<Failure, Unit>> delete() async {
    if (!state.isEdit || state.initial == null) {
      const failure = BusinessFailure('Não é possível deletar um veículo que não foi salvo.');
      _setFailure(failure);
      return left(failure);
    }
    _state = _state.copyWith(isLoading: true);

    final response = await _deleteVehicle(state.initial!.id);
    response.fold(_setFailure, (_) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    });
    return response;
  }

  Future<void> onPickLocalPhoto(File file) async {
    await track(() async {
      final old = state.photoPath;
      final response = await _savePhoto(file: file, oldPath: old);

      response.fold(
        (failure) => _setFailure(failure),
        (newPath) async {
          _stagedToDeletePhotoPath = null;
          _state = _state.copyWith(photoPath: newPath);
          notifyListeners();
        },
      );
    });
  }

  void onRemovePhoto() {
    _stagedToDeletePhotoPath = state.photoPath;
    _state = _state.copyWith(clearPhotoPath: true);
    notifyListeners();
  }

  void _cleanupStagedPhoto() {
    final toDelete = _stagedToDeletePhotoPath;
    if (toDelete != null && toDelete.isNotEmpty) {
      _deletePhoto(toDelete).ignore();
      _stagedToDeletePhotoPath = null;
    }
  }

  void _setFailure(Failure failure) {
    _state = _state.copyWith(isLoading: false, errorMessage: failure.message);
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

  void updateFuelType(FuelType value) {
    _state = _state.copyWith(fuelType: value);
    notifyListeners();
  }

  void updatePhotoPath(String? value) {
    _state = _state.copyWith(photoPath: value, clearPhotoPath: value == null);
    notifyListeners();
  }

  @override
  void dispose() {
    nameEC.dispose();
    plateEC.dispose();
    tankCapacityEC.dispose();
    super.dispose();
  }
}

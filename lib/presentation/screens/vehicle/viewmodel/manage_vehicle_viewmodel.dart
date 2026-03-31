import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gasosa_app/application/photos/delete_photo_use_case.dart';
import 'package:gasosa_app/application/photos/save_photo_use_case.dart';
import 'package:gasosa_app/application/vehicles/create_or_update_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/delete_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/get_vehicle_by_id_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/helpers/numeric_parser.dart';
import 'package:gasosa_app/core/helpers/uuid.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:injectable/injectable.dart';

class ManageVehicleState {
  const ManageVehicleState({
    this.initial,
    this.name = '',
    this.plate = '',
    this.tankCapacity = '',
    this.fuelType = FuelType.flex,
    this.photoPath = '',
    this.isEdit = false,
  });

  final VehicleEntity? initial;
  final String name;
  final String plate;
  final String tankCapacity;
  final FuelType fuelType;
  final String? photoPath;
  final bool isEdit;

  ManageVehicleState copyWith({
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

@injectable
class ManageVehicleViewModel {
  ManageVehicleViewModel(
    this._auth,
    this._getVehicleById,
    this._saveVehicle,
    this._deleteVehicle,
    this._savePhoto,
    this._deletePhoto,
  ) : state = ValueNotifier(const ManageVehicleState()),
      loadCommand = Command<Unit>(),
      saveCommand = Command<Unit>(),
      deleteCommand = Command<Unit>(),
      photoCommand = Command<String>();

  final AuthService _auth;
  String _userId = '';
  final GetVehicleByIdUseCase _getVehicleById;
  final CreateOrUpdateVehicleUseCase _saveVehicle;
  final DeleteVehicleUseCase _deleteVehicle;
  final SavePhotoUseCase _savePhoto;
  final DeletePhotoUseCase _deletePhoto;

  final ValueNotifier<ManageVehicleState> state;
  final Command<Unit> loadCommand;
  final Command<Unit> saveCommand;
  final Command<Unit> deleteCommand;
  final Command<String> photoCommand;

  String? _stagedToDeletePhotoPath;

  FuelType get fuelType => state.value.fuelType;

  Future<void> init({String? vehicleId}) async {
    _userId = (await _auth.currentUser())?.id ?? '';
    if (vehicleId == null || vehicleId.isEmpty) return;

    await loadCommand.run(() async {
      final either = await _getVehicleById(vehicleId);
      final Either<Failure, VehicleEntity> result = either.flatMap((vehicle) {
        if (vehicle == null) {
          return const Left(ValidationFailure('Veículo não encontrado'));
        }
        return Right(vehicle);
      });
      result.fold(
        (_) {},
        (vehicle) {
          state.value = state.value.copyWith(
            isEdit: true,
            initial: vehicle,
            name: vehicle.name,
            plate: vehicle.plate ?? '',
            tankCapacity: vehicle.tankCapacity?.toString() ?? '',
            fuelType: vehicle.fuelType,
            photoPath: vehicle.photoPath ?? '',
          );
        },
      );
      return result.map((_) => unit);
    });
  }

  VehicleEntity _buildEntity() {
    final uid = _userId;
    final s = state.value;
    final isEdit = s.isEdit && s.initial != null;

    return VehicleEntity(
      id: isEdit ? s.initial!.id : UuidHelper.generate(),
      userId: uid,
      name: s.name.trim(),
      plate: s.plate.trim().isEmpty ? null : s.plate.trim(),
      tankCapacity: _parseCapacity(s.tankCapacity.trim()),
      fuelType: s.fuelType,
      photoPath: s.photoPath,
      createdAt: isEdit ? s.initial!.createdAt : DateTime.now(),
      updatedAt: isEdit ? DateTime.now() : null,
    );
  }

  double? _parseCapacity(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return NumericParser.parseDouble(trimmed);
  }

  Future<Either<Failure, Unit>?> save() async {
    final result = await saveCommand.run(() => _saveVehicle(_buildEntity()));
    if (result?.isRight == true) _cleanupStagedPhoto();
    return result;
  }

  Future<Either<Failure, Unit>?> delete() async {
    final s = state.value;
    if (!s.isEdit || s.initial == null) {
      return const Left(ValidationFailure('Não é possível deletar um veículo que não foi salvo.'));
    }
    return deleteCommand.run(() => _deleteVehicle(s.initial!.id));
  }

  Future<void> onPickLocalPhoto(File file) async {
    final result = await photoCommand.run(
      () => _savePhoto(file: file, oldPath: state.value.photoPath),
    );
    result?.fold(
      (_) {},
      (newPath) {
        _stagedToDeletePhotoPath = null;
        state.value = state.value.copyWith(photoPath: newPath);
      },
    );
  }

  void onRemovePhoto() {
    _stagedToDeletePhotoPath = state.value.photoPath;
    state.value = state.value.copyWith(clearPhotoPath: true);
  }

  void _cleanupStagedPhoto() {
    final toDelete = _stagedToDeletePhotoPath;
    if (toDelete != null && toDelete.isNotEmpty) {
      _deletePhoto(toDelete).ignore();
      _stagedToDeletePhotoPath = null;
    }
  }

  void updateName(String value) => state.value = state.value.copyWith(name: value);

  void updatePlate(String value) => state.value = state.value.copyWith(plate: value);

  void updateTankCapacity(String value) => state.value = state.value.copyWith(tankCapacity: value);

  void updateFuelType(FuelType value) => state.value = state.value.copyWith(fuelType: value);

  void dispose() {
    state.dispose();
    loadCommand.dispose();
    saveCommand.dispose();
    deleteCommand.dispose();
    photoCommand.dispose();
  }
}

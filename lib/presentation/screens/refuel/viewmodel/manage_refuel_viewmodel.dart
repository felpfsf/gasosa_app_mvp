import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/application/commands/photos/delete_photo_command.dart';
import 'package:gasosa_app/application/commands/photos/save_photo_command.dart';
import 'package:gasosa_app/application/commands/refuel/create_or_update_refuel_command.dart';
import 'package:gasosa_app/application/commands/refuel/delete_refuel_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/helpers/uuid.dart';
import 'package:gasosa_app/core/validators/refuel_validators.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';

class ManageRefuelState {
  ManageRefuelState({
    this.isLoading = false,
    this.errorMessage,
    this.initial,
    this.vehicle,
    this.isEditing = false,
    this.mileage = 0,
    this.totalValue = 0.0,
    this.liters = 0.0,
    this.coldStartLiters,
    this.coldStartValue,
    this.receiptPath,
    this.fuelType = FuelType.gasoline,
    this.availableFuelTypes = const [FuelType.gasoline],
    this.previousMileage,
    DateTime? refuelDate,
  }) : refuelDate = refuelDate ?? DateTime.now();

  final bool isLoading;
  final String? errorMessage;
  final RefuelEntity? initial;
  final VehicleEntity? vehicle;
  final bool isEditing;
  final int mileage;
  final double totalValue;
  final double liters;
  final double? coldStartLiters;
  final double? coldStartValue;
  final String? receiptPath;
  final DateTime refuelDate;
  final FuelType fuelType;
  final List<FuelType> availableFuelTypes;
  final int? previousMileage;

  ManageRefuelState copyWith({
    bool? isLoading,
    String? errorMessage,
    RefuelEntity? initial,
    VehicleEntity? vehicle,
    bool? isEditing,
    int? mileage,
    double? totalValue,
    double? liters,
    double? coldStartLiters,
    double? coldStartValue,
    String? receiptPath,
    DateTime? refuelDate,
    FuelType? fuelType,
    List<FuelType>? availableFuelTypes,
    int? previousMileage,
    bool clearPhotoPath = false,
  }) {
    return ManageRefuelState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      initial: initial ?? this.initial,
      vehicle: vehicle ?? this.vehicle,
      isEditing: isEditing ?? this.isEditing,
      mileage: mileage ?? this.mileage,
      totalValue: totalValue ?? this.totalValue,
      liters: liters ?? this.liters,
      coldStartLiters: coldStartLiters ?? this.coldStartLiters,
      coldStartValue: coldStartValue ?? this.coldStartValue,
      receiptPath: clearPhotoPath ? null : (receiptPath ?? this.receiptPath),
      refuelDate: refuelDate ?? this.refuelDate,
      fuelType: fuelType ?? this.fuelType,
      availableFuelTypes: availableFuelTypes ?? this.availableFuelTypes,
      previousMileage: previousMileage ?? this.previousMileage,
    );
  }
}

class ManageRefuelViewmodel extends BaseViewModel {
  ManageRefuelViewmodel({
    required RefuelRepository repository,
    required VehicleRepository vehicleRepository,
    required LoadingController loading,
    required CreateOrUpdateRefuelCommand saveRefuel,
    required SavePhotoCommand saveReceiptPhoto,
    required DeletePhotoCommand deleteReceiptPhoto,
    required DeleteRefuelCommand deleteRefuel,
  }) : _repository = repository,
       _vehicleRepository = vehicleRepository,
       _saveRefuel = saveRefuel,
       _saveReceiptPhoto = saveReceiptPhoto,
       _deleteReceiptPhoto = deleteReceiptPhoto,
       _deleteRefuel = deleteRefuel,
       super(loading);

  final RefuelRepository _repository;
  final VehicleRepository _vehicleRepository;
  final CreateOrUpdateRefuelCommand _saveRefuel;
  final DeleteRefuelCommand _deleteRefuel;
  final SavePhotoCommand _saveReceiptPhoto;
  final DeletePhotoCommand _deleteReceiptPhoto;

  ManageRefuelState _state = ManageRefuelState();
  ManageRefuelState get state => _state;

  String? _stagedToDeletePhotoPath;

  final mileageEC = TextEditingController();
  final totalValueEC = TextEditingController();
  final litersEC = TextEditingController();
  final coldStartLitersEC = TextEditingController();
  final coldStartValueEC = TextEditingController();
  bool hasColdStart = false;
  bool hasReceiptPhoto = false;
  FuelType fuelType = FuelType.gasoline;

  @override
  void setViewLoading({bool value = false}) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

  void _setFailure(Failure failure) {
    _state = _state.copyWith(isLoading: false, errorMessage: failure.message);
    notifyListeners();
  }

  Future<void> init(String? id, String? vehicleId) async {
    if (id != null && id.isNotEmpty) {
      setViewLoading(value: true);
      final either = await _repository.getRefuelById(id);
      either.fold(
        _setFailure,
        (refuel) async {
          if (refuel == null) {
            _setFailure(const BusinessFailure('Abastecimento não encontrado'));
            return;
          }

          await _loadVehicleData(refuel.vehicleId);
          await _loadPreviousMileage(refuel.vehicleId, refuel.createdAt, refuel.mileage);

          _state = _state.copyWith(
            isLoading: false,
            isEditing: true,
            initial: refuel,
            mileage: refuel.mileage,
            totalValue: refuel.totalValue,
            liters: refuel.liters,
            coldStartLiters: refuel.coldStartLiters,
            coldStartValue: refuel.coldStartValue,
            receiptPath: refuel.receiptPath,
            refuelDate: refuel.refuelDate,
            fuelType: refuel.fuelType,
          );

          mileageEC.text = _state.mileage.toString();
          totalValueEC.text = _state.totalValue.toString();
          litersEC.text = _state.liters.toString();
          coldStartLitersEC.text = _state.coldStartLiters.toString();
          coldStartValueEC.text = _state.coldStartValue.toString();
          hasColdStart = _state.coldStartLiters != null && _state.coldStartValue != null;
          fuelType = _state.fuelType;
          hasReceiptPhoto = _state.receiptPath != null;

          notifyListeners();
        },
      );
    } else if (vehicleId != null && vehicleId.isNotEmpty) {
      await initWithVehicle(vehicleId);
    } else {
      _setFailure(const BusinessFailure('ID do veículo é obrigatório para novo abastecimento.'));
    }
  }

  Future<void> initWithVehicle(String vehicleId) async {
    setViewLoading(value: true);
    await _loadVehicleData(vehicleId);
    await _loadPreviousMileage(vehicleId, DateTime.now(), 0);
    _state = _state.copyWith(isLoading: false);
    _populateControllers();
    notifyListeners();
  }

  List<FuelType> _calculateAvailableFuelTypes(VehicleEntity vehicle) {
    switch (vehicle.fuelType) {
      case FuelType.flex:
        return [FuelType.gasoline, FuelType.ethanol];
      case FuelType.gasoline:
      case FuelType.ethanol:
      case FuelType.diesel:
      case FuelType.gnv:
        return [vehicle.fuelType];
    }
  }

  bool get vehicleHasColdStartReservoir {
    if (state.vehicle?.fuelType == null) return false;

    final result =
        state.vehicle!.fuelType == FuelType.ethanol ||
        state.vehicle!.fuelType == FuelType.flex ||
        state.vehicle!.fuelType == FuelType.gnv;
    return result;
  }

  bool get shouldShowColdStart {
    if (!vehicleHasColdStartReservoir) return false;

    if (state.vehicle?.fuelType == FuelType.flex) return true;

    return state.fuelType == FuelType.ethanol || state.fuelType == FuelType.gnv;
  }

  bool get shouldShowReceiptPhotoInput {
    return hasReceiptPhoto;
  }

  String? Function(String?) get mileageValidator {
    return (String? value) {
      // First apply basic validations
      final basicValidation = RefuelValidators.mileage(value);
      if (basicValidation != null) {
        return basicValidation;
      }

      // Check if mileage is less than previous
      if (state.previousMileage != null) {
        final currentMileage = int.tryParse(value ?? '0') ?? 0;
        if (currentMileage < state.previousMileage!) {
          return 'KM não pode ser menor que o abastecimento anterior (${state.previousMileage} km)';
        }
      }

      return null;
    };
  }

  Future<void> _loadVehicleData(String vehicleId) async {
    final vehicleEither = await _vehicleRepository.getVehicleById(vehicleId);
    vehicleEither.fold(
      (failure) => _setFailure(failure),
      (vehicle) {
        if (vehicle != null) {
          final availableFuelTypes = _calculateAvailableFuelTypes(vehicle);

          final defaultFuelType = availableFuelTypes.first;

          _state = _state.copyWith(
            vehicle: vehicle,
            availableFuelTypes: availableFuelTypes,
            fuelType: defaultFuelType,
          );

          fuelType = defaultFuelType; // TODO(felipe): Talvez não é necessário
        }
      },
    );
  }

  Future<void> _loadPreviousMileage(String vehicleId, DateTime createdAt, int mileage) async {
    final previousEither = await _repository.getPreviousByVehicleId(
      vehicleId,
      createdAt: createdAt,
      mileage: mileage,
    );
    previousEither.fold(
      (failure) {
        // Silently ignore failure - no previous refuel is okay
      },
      (previousRefuel) {
        if (previousRefuel != null) {
          _state = _state.copyWith(previousMileage: previousRefuel.mileage);
        }
      },
    );
  }

  void _populateControllers() {
    if (state.isEditing && state.initial != null) {
      mileageEC.text = _state.mileage.toString();
      totalValueEC.text = _state.totalValue.toStringAsFixed(2).replaceAll('.', ',');
      litersEC.text = _state.liters.toStringAsFixed(2).replaceAll('.', ',');
      coldStartLitersEC.text = _state.coldStartLiters?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      coldStartValueEC.text = _state.coldStartValue?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      hasColdStart = _state.coldStartLiters != null && _state.coldStartValue != null;
      hasReceiptPhoto = _state.receiptPath != null;
    } else {
      mileageEC.clear();
      totalValueEC.clear();
      litersEC.clear();
      coldStartLitersEC.clear();
      coldStartValueEC.clear();
      hasColdStart = false;
      hasReceiptPhoto = false;
    }
    fuelType = state.fuelType;
  }

  RefuelEntity _buildEntity() {
    final isEditing = state.isEditing && state.initial != null;

    return RefuelEntity(
      id: isEditing ? state.initial!.id : UuidHelper.generate(),
      vehicleId: state.initial?.vehicleId ?? state.vehicle?.id ?? '',
      mileage: state.mileage,
      totalValue: state.totalValue,
      liters: state.liters,
      coldStartLiters: hasColdStart ? state.coldStartLiters : null,
      coldStartValue: hasColdStart ? state.coldStartValue : null,
      receiptPath: hasReceiptPhoto ? state.receiptPath : null,
      refuelDate: state.refuelDate,
      fuelType: state.fuelType,
      createdAt: isEditing ? state.initial!.createdAt : DateTime.now(),
      updatedAt: isEditing ? DateTime.now() : null,
    );
  }

  Future<Either<Failure, Unit>> save() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final entity = _buildEntity();
    final response = await _saveRefuel.call(entity);

    response.fold(
      _setFailure,
      (_) {
        _state = _state.copyWith(isLoading: false);
        notifyListeners();

        _cleanupStagedPhoto();
      },
    );

    return response;
  }

  Future<Either<Failure, Unit>> delete() async {
    if (!state.isEditing || state.initial == null) {
      const failure = BusinessFailure('Não é possível excluir um abastecimento que não foi salvo.');
      _setFailure(failure);
      return left(failure);
    }
    _state = _state.copyWith(isLoading: true);

    final response = await _deleteRefuel(state.initial!.id);
    response.fold(_setFailure, (_) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    });

    return response;
  }

  Future<void> onPickLocalPhoto(File file) async {
    await track(() async {
      final old = state.receiptPath;
      final response = await _saveReceiptPhoto(file: file, oldPath: old);

      response.fold(
        (failure) => _setFailure(failure),
        (newPath) {
          _stagedToDeletePhotoPath = null;
          _state = _state.copyWith(receiptPath: newPath);
          notifyListeners();
        },
      );
    });
  }

  void onRemovePhoto() {
    _stagedToDeletePhotoPath = state.receiptPath;
    _state = _state.copyWith(clearPhotoPath: true);
    notifyListeners();
  }

  void _cleanupStagedPhoto() {
    final toDelete = _stagedToDeletePhotoPath;
    if (toDelete != null && toDelete.isNotEmpty) {
      _deleteReceiptPhoto(toDelete).ignore();
      _stagedToDeletePhotoPath = null;
    }
  }

  void _updateNumericValue<T>({
    required String value,
    required T Function(String) parser,
    required T defaultValue,
    required ManageRefuelState Function(T) stateUpdater,
  }) {
    final T parsedValue = value.trim().isEmpty ? defaultValue : parser(value.replaceAll(',', '.')) ?? defaultValue;

    _state = stateUpdater(parsedValue);
    notifyListeners();
  }

  void updateRefuelDate(DateTime date) {
    _state = _state.copyWith(refuelDate: date);
    notifyListeners();
  }

  void updateMileage(String value) {
    _updateNumericValue<int>(
      value: value,
      parser: (value) => int.tryParse(value) ?? 0,
      defaultValue: 0,
      stateUpdater: (parsed) => _state.copyWith(mileage: parsed),
    );
  }

  void updateTotalValue(String value) {
    _updateNumericValue<double>(
      value: value,
      parser: (value) => double.tryParse(value) ?? 0.0,
      defaultValue: 0.0,
      stateUpdater: (parsed) => _state.copyWith(totalValue: parsed),
    );
  }

  void updateLiters(String value) {
    _updateNumericValue<double>(
      value: value,
      parser: (value) => double.tryParse(value) ?? 0.0,
      defaultValue: 0.0,
      stateUpdater: (parsed) => _state.copyWith(liters: parsed),
    );
  }

  void updateColdStartLiters(String value) {
    _updateNumericValue<double>(
      value: value,
      parser: (value) => double.tryParse(value) ?? 0.0,
      defaultValue: 0.0,
      stateUpdater: (parsed) => _state.copyWith(coldStartLiters: parsed),
    );
  }

  void updateColdStartValue(String value) {
    _updateNumericValue<double>(
      value: value,
      parser: (value) => double.tryParse(value) ?? 0.0,
      defaultValue: 0.0,
      stateUpdater: (parsed) => _state.copyWith(coldStartValue: parsed),
    );
  }

  void updateFuelType(FuelType value) {
    fuelType = value;
    _state = _state.copyWith(fuelType: value);
    notifyListeners();
  }

  void updateReceiptPath(String? value) {
    _state = _state.copyWith(receiptPath: value, clearPhotoPath: value == null);
    notifyListeners();
  }

  @override
  void dispose() {
    mileageEC.dispose();
    totalValueEC.dispose();
    litersEC.dispose();
    coldStartLitersEC.dispose();
    coldStartValueEC.dispose();
    super.dispose();
  }
}

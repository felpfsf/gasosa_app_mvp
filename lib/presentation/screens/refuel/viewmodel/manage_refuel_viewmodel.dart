import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/application/commands/photos/delete_photo_command.dart';
import 'package:gasosa_app/application/commands/photos/save_photo_command.dart';
import 'package:gasosa_app/application/commands/refuel/create_or_update_refuel_command.dart';
import 'package:gasosa_app/application/commands/refuel/delete_refuel_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/helpers/numeric_parser.dart';
import 'package:gasosa_app/core/helpers/uuid.dart';
import 'package:gasosa_app/core/validators/refuel_validators.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:gasosa_app/domain/services/refuel_business_rules.dart';

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
    this.wantsReceiptPhoto = false,
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
  final bool wantsReceiptPhoto;
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
    bool? wantsReceiptPhoto,
    DateTime? refuelDate,
    FuelType? fuelType,
    List<FuelType>? availableFuelTypes,
    int? previousMileage,
    bool clearPhotoPath = false,
    bool clearColdStart = false,
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
      coldStartLiters: clearColdStart ? null : (coldStartLiters ?? this.coldStartLiters),
      coldStartValue: clearColdStart ? null : (coldStartValue ?? this.coldStartValue),
      receiptPath: clearPhotoPath ? null : (receiptPath ?? this.receiptPath),
      wantsReceiptPhoto: clearPhotoPath ? false : (wantsReceiptPhoto ?? this.wantsReceiptPhoto),
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
    required RefuelBusinessRules businessRules,
  }) : _repository = repository,
       _vehicleRepository = vehicleRepository,
       _saveRefuel = saveRefuel,
       _saveReceiptPhoto = saveReceiptPhoto,
       _deleteReceiptPhoto = deleteReceiptPhoto,
       _deleteRefuel = deleteRefuel,
       _businessRules = businessRules,
       super(loading);

  final RefuelRepository _repository;
  final VehicleRepository _vehicleRepository;
  final CreateOrUpdateRefuelCommand _saveRefuel;
  final DeleteRefuelCommand _deleteRefuel;
  final SavePhotoCommand _saveReceiptPhoto;
  final DeletePhotoCommand _deleteReceiptPhoto;
  final RefuelBusinessRules _businessRules;

  ManageRefuelState _state = ManageRefuelState();
  ManageRefuelState get state => _state;

  String? _stagedToDeletePhotoPath;

  final mileageEC = TextEditingController();
  final totalValueEC = TextEditingController();
  final litersEC = TextEditingController();
  final coldStartLitersEC = TextEditingController();
  final coldStartValueEC = TextEditingController();

  bool get hasColdStart => state.coldStartLiters != null && state.coldStartValue != null;
  set hasColdStart(bool value) {
    if (value && !hasColdStart) {
      // Initialize with zero when checked
      _state = _state.copyWith(coldStartLiters: 0.0, coldStartValue: 0.0);
      notifyListeners();
    } else if (!value && hasColdStart) {
      // Clear cold start values when unchecked
      _state = _state.copyWith(clearColdStart: true);
      coldStartLitersEC.clear();
      coldStartValueEC.clear();
      notifyListeners();
    }
  }

  bool get hasReceiptPhoto => state.wantsReceiptPhoto || state.receiptPath != null;
  set hasReceiptPhoto(bool value) {
    if (value) {
      // User wants to add photo
      _state = _state.copyWith(wantsReceiptPhoto: true);
      notifyListeners();
    } else {
      // User doesn't want photo - clear everything
      if (state.receiptPath != null) {
        onRemovePhoto();
      } else {
        _state = _state.copyWith(wantsReceiptPhoto: false);
        notifyListeners();
      }
    }
  }

  FuelType get fuelType => state.fuelType;

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
            wantsReceiptPhoto: refuel.receiptPath != null,
            refuelDate: refuel.refuelDate,
            fuelType: refuel.fuelType,
          );

          _populateControllers();
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

  bool get vehicleHasColdStartReservoir {
    final vehicle = state.vehicle;
    if (vehicle == null) return false;
    return _businessRules.vehicleHasColdStartReservoir(vehicle);
  }

  bool get shouldShowColdStart {
    final vehicle = state.vehicle;
    if (vehicle == null) return false;
    return _businessRules.shouldShowColdStart(
      vehicle: vehicle,
      selectedFuelType: state.fuelType,
    );
  }

  bool get shouldShowReceiptPhotoInput => hasReceiptPhoto;

  String? Function(String?) get mileageValidator {
    return (String? value) {
      final basicValidation = RefuelValidators.mileage(value);
      if (basicValidation != null) {
        return basicValidation;
      }

      final currentMileage = NumericParser.parseInt(value);
      return _businessRules.validateMileageAgainstPrevious(
        currentMileage: currentMileage,
        previousMileage: state.previousMileage,
      );
    };
  }

  Future<void> _loadVehicleData(String vehicleId) async {
    final vehicleEither = await _vehicleRepository.getVehicleById(vehicleId);
    vehicleEither.fold(
      (failure) => _setFailure(failure),
      (vehicle) {
        if (vehicle != null) {
          final availableFuelTypes = _businessRules.getAvailableFuelTypes(vehicle);
          final defaultFuelType = availableFuelTypes.first;

          _state = _state.copyWith(
            vehicle: vehicle,
            availableFuelTypes: availableFuelTypes,
            fuelType: defaultFuelType,
          );
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
      (failure) {},
      (previousRefuel) {
        if (previousRefuel != null) {
          _state = _state.copyWith(previousMileage: previousRefuel.mileage);
        }
      },
    );
  }

  void _populateControllers() {
    if (state.isEditing && state.initial != null) {
      mileageEC.text = NumericParser.formatInt(_state.mileage);
      totalValueEC.text = NumericParser.formatDouble(_state.totalValue);
      litersEC.text = NumericParser.formatDouble(_state.liters);
      coldStartLitersEC.text = _state.coldStartLiters != null
          ? NumericParser.formatDouble(_state.coldStartLiters!)
          : '';
      coldStartValueEC.text = _state.coldStartValue != null ? NumericParser.formatDouble(_state.coldStartValue!) : '';
    } else {
      mileageEC.clear();
      totalValueEC.clear();
      litersEC.clear();
      coldStartLitersEC.clear();
      coldStartValueEC.clear();
    }
  }

  RefuelEntity _buildEntity() {
    final isEditing = state.isEditing && state.initial != null;

    return RefuelEntity(
      id: isEditing ? state.initial!.id : UuidHelper.generate(),
      vehicleId: state.initial?.vehicleId ?? state.vehicle?.id ?? '',
      mileage: state.mileage,
      totalValue: state.totalValue,
      liters: state.liters,
      coldStartLiters: state.coldStartLiters,
      coldStartValue: state.coldStartValue,
      receiptPath: state.receiptPath,
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
          _state = _state.copyWith(
            receiptPath: newPath,
            wantsReceiptPhoto: true,
          );
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

  void updateRefuelDate(DateTime date) {
    _state = _state.copyWith(refuelDate: date);
    notifyListeners();
  }

  void updateMileage(String value) {
    _state = _state.copyWith(mileage: NumericParser.parseInt(value));
    notifyListeners();
  }

  void updateTotalValue(String value) {
    _state = _state.copyWith(totalValue: NumericParser.parseDouble(value));
    notifyListeners();
  }

  void updateLiters(String value) {
    _state = _state.copyWith(liters: NumericParser.parseDouble(value));
    notifyListeners();
  }

  void updateColdStartLiters(String value) {
    _state = _state.copyWith(coldStartLiters: NumericParser.parseDouble(value));
    notifyListeners();
  }

  void updateColdStartValue(String value) {
    _state = _state.copyWith(coldStartValue: NumericParser.parseDouble(value));
    notifyListeners();
  }

  void updateFuelType(FuelType value) {
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

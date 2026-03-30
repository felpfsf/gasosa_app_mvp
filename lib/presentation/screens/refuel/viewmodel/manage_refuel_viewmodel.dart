import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/application/photos/delete_photo_use_case.dart';
import 'package:gasosa_app/application/photos/save_photo_use_case.dart';
import 'package:gasosa_app/application/refuel/create_or_update_refuel_use_case.dart';
import 'package:gasosa_app/application/refuel/delete_refuel_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/helpers/numeric_parser.dart';
import 'package:gasosa_app/core/helpers/uuid.dart';
import 'package:gasosa_app/core/presentation/command.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/core/validators/refuel_validators.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';
import 'package:gasosa_app/domain/repositories/vehicle_repository.dart';
import 'package:gasosa_app/domain/services/refuel_business_rules.dart';
import 'package:injectable/injectable.dart';

class ManageRefuelState {
  ManageRefuelState({
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

@injectable
class ManageRefuelViewmodel {
  ManageRefuelViewmodel(
    this._repository,
    this._vehicleRepository,
    this._saveRefuel,
    this._saveReceiptPhoto,
    this._deleteReceiptPhoto,
    this._deleteRefuel,
    this._businessRules,
  ) : state = ValueNotifier(ManageRefuelState()),
      loadCommand = Command<void>(),
      saveCommand = Command<Unit>(),
      deleteCommand = Command<Unit>(),
      photoCommand = Command<String>();

  final RefuelRepository _repository;
  final VehicleRepository _vehicleRepository;
  final CreateOrUpdateRefuelUseCase _saveRefuel;
  final DeleteRefuelUseCase _deleteRefuel;
  final SavePhotoUseCase _saveReceiptPhoto;
  final DeletePhotoUseCase _deleteReceiptPhoto;
  final RefuelBusinessRules _businessRules;

  final ValueNotifier<ManageRefuelState> state;
  final Command<void> loadCommand;
  final Command<Unit> saveCommand;
  final Command<Unit> deleteCommand;
  final Command<String> photoCommand;

  String? _stagedToDeletePhotoPath;

  final mileageEC = TextEditingController();
  final totalValueEC = TextEditingController();
  final litersEC = TextEditingController();
  final coldStartLitersEC = TextEditingController();
  final coldStartValueEC = TextEditingController();

  bool get hasColdStart => state.value.coldStartLiters != null && state.value.coldStartValue != null;

  set hasColdStart(bool value) {
    if (value && !hasColdStart) {
      state.value = state.value.copyWith(coldStartLiters: 0.0, coldStartValue: 0.0);
    } else if (!value && hasColdStart) {
      state.value = state.value.copyWith(clearColdStart: true);
      coldStartLitersEC.clear();
      coldStartValueEC.clear();
    }
  }

  bool get hasReceiptPhoto => state.value.wantsReceiptPhoto || state.value.receiptPath != null;

  set hasReceiptPhoto(bool value) {
    if (value) {
      state.value = state.value.copyWith(wantsReceiptPhoto: true);
    } else {
      if (state.value.receiptPath != null) {
        onRemovePhoto();
      } else {
        state.value = state.value.copyWith(wantsReceiptPhoto: false);
      }
    }
  }

  FuelType get fuelType => state.value.fuelType;

  Future<void> init(String? id, String? vehicleId) async {
    if (id != null && id.isNotEmpty) {
      await loadCommand.run(() async {
        final either = await _repository.getRefuelById(id);
        if (either is Left<Failure, RefuelEntity?>) {
          return Left<Failure, void>(either.value);
        }
        final refuel = (either as Right<Failure, RefuelEntity?>).value;
        if (refuel == null) {
          return const Left(ValidationFailure('Abastecimento não encontrado'));
        }
        await _loadVehicleData(refuel.vehicleId);
        await _loadPreviousMileage(refuel.vehicleId, refuel.createdAt, refuel.mileage);
        state.value = state.value.copyWith(
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
        return right(null);
      });
    } else if (vehicleId != null && vehicleId.isNotEmpty) {
      await initWithVehicle(vehicleId);
    } else {
      loadCommand.state.value = const UiError(
        ValidationFailure('ID do veículo é obrigatório para novo abastecimento.'),
      );
    }
  }

  Future<void> initWithVehicle(String vehicleId) async {
    await loadCommand.run(() async {
      await _loadVehicleData(vehicleId);
      await _loadPreviousMileage(vehicleId, DateTime.now(), 0);
      _populateControllers();
      return right(null);
    });
  }

  bool get vehicleHasColdStartReservoir {
    final vehicle = state.value.vehicle;
    if (vehicle == null) return false;
    return _businessRules.vehicleHasColdStartReservoir(vehicle);
  }

  bool get shouldShowColdStart {
    final vehicle = state.value.vehicle;
    if (vehicle == null) return false;
    return _businessRules.shouldShowColdStart(
      vehicle: vehicle,
      selectedFuelType: state.value.fuelType,
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
        previousMileage: state.value.previousMileage,
      );
    };
  }

  Future<void> _loadVehicleData(String vehicleId) async {
    final vehicleEither = await _vehicleRepository.getVehicleById(vehicleId);
    vehicleEither.fold(
      (_) {},
      (vehicle) {
        if (vehicle != null) {
          final availableFuelTypes = _businessRules.getAvailableFuelTypes(vehicle);
          state.value = state.value.copyWith(
            vehicle: vehicle,
            availableFuelTypes: availableFuelTypes,
            fuelType: availableFuelTypes.first,
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
      (_) {},
      (previousRefuel) {
        if (previousRefuel != null) {
          state.value = state.value.copyWith(previousMileage: previousRefuel.mileage);
        }
      },
    );
  }

  void _populateControllers() {
    final s = state.value;
    if (s.isEditing && s.initial != null) {
      mileageEC.text = NumericParser.formatInt(s.mileage);
      totalValueEC.text = NumericParser.formatDouble(s.totalValue);
      litersEC.text = NumericParser.formatDouble(s.liters);
      coldStartLitersEC.text = s.coldStartLiters != null ? NumericParser.formatDouble(s.coldStartLiters!) : '';
      coldStartValueEC.text = s.coldStartValue != null ? NumericParser.formatDouble(s.coldStartValue!) : '';
    } else {
      mileageEC.clear();
      totalValueEC.clear();
      litersEC.clear();
      coldStartLitersEC.clear();
      coldStartValueEC.clear();
    }
  }

  RefuelEntity _buildEntity() {
    final s = state.value;
    final isEditing = s.isEditing && s.initial != null;
    return RefuelEntity(
      id: isEditing ? s.initial!.id : UuidHelper.generate(),
      vehicleId: s.initial?.vehicleId ?? s.vehicle?.id ?? '',
      mileage: s.mileage,
      totalValue: s.totalValue,
      liters: s.liters,
      coldStartLiters: s.coldStartLiters,
      coldStartValue: s.coldStartValue,
      receiptPath: s.receiptPath,
      refuelDate: s.refuelDate,
      fuelType: s.fuelType,
      createdAt: isEditing ? s.initial!.createdAt : DateTime.now(),
      updatedAt: isEditing ? DateTime.now() : null,
    );
  }

  Future<Either<Failure, Unit>?> save() async {
    final result = await saveCommand.run(() => _saveRefuel(_buildEntity()));
    if (result?.isRight == true) _cleanupStagedPhoto();
    return result;
  }

  Future<Either<Failure, Unit>?> delete() async {
    final s = state.value;
    if (!s.isEditing || s.initial == null) {
      return const Left(
        ValidationFailure('Não é possível excluir um abastecimento que não foi salvo.'),
      );
    }
    return deleteCommand.run(() => _deleteRefuel(s.initial!.id));
  }

  Future<void> onPickLocalPhoto(File file) async {
    final result = await photoCommand.run(
      () => _saveReceiptPhoto(file: file, oldPath: state.value.receiptPath),
    );
    result?.fold(
      (_) {},
      (newPath) {
        _stagedToDeletePhotoPath = null;
        state.value = state.value.copyWith(receiptPath: newPath, wantsReceiptPhoto: true);
      },
    );
  }

  void onRemovePhoto() {
    _stagedToDeletePhotoPath = state.value.receiptPath;
    state.value = state.value.copyWith(clearPhotoPath: true);
  }

  void _cleanupStagedPhoto() {
    final toDelete = _stagedToDeletePhotoPath;
    if (toDelete != null && toDelete.isNotEmpty) {
      _deleteReceiptPhoto(toDelete).ignore();
      _stagedToDeletePhotoPath = null;
    }
  }

  void updateRefuelDate(DateTime date) => state.value = state.value.copyWith(refuelDate: date);

  void updateMileage(String value) => state.value = state.value.copyWith(mileage: NumericParser.parseInt(value));

  void updateTotalValue(String value) =>
      state.value = state.value.copyWith(totalValue: NumericParser.parseDouble(value));

  void updateLiters(String value) => state.value = state.value.copyWith(liters: NumericParser.parseDouble(value));

  void updateColdStartLiters(String value) =>
      state.value = state.value.copyWith(coldStartLiters: NumericParser.parseDouble(value));

  void updateColdStartValue(String value) =>
      state.value = state.value.copyWith(coldStartValue: NumericParser.parseDouble(value));

  void updateFuelType(FuelType value) => state.value = state.value.copyWith(fuelType: value);

  void updateReceiptPath(String? value) =>
      state.value = state.value.copyWith(receiptPath: value, clearPhotoPath: value == null);

  void dispose() {
    state.dispose();
    loadCommand.dispose();
    saveCommand.dispose();
    deleteCommand.dispose();
    photoCommand.dispose();
    mileageEC.dispose();
    totalValueEC.dispose();
    litersEC.dispose();
    coldStartLitersEC.dispose();
    coldStartValueEC.dispose();
  }
}

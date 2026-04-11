import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gasosa_app/application/photos/delete_photo_use_case.dart';
import 'package:gasosa_app/application/photos/save_photo_use_case.dart';
import 'package:gasosa_app/application/refuel/create_or_update_refuel_use_case.dart';
import 'package:gasosa_app/application/refuel/delete_refuel_use_case.dart';
import 'package:gasosa_app/application/refuel/get_previous_refuel_use_case.dart';
import 'package:gasosa_app/application/refuel/get_refuel_by_id_use_case.dart';
import 'package:gasosa_app/application/vehicles/get_vehicle_by_id_use_case.dart';
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
import 'package:gasosa_app/domain/services/refuel_business_rules.dart';
import 'package:injectable/injectable.dart';

class ManageRefuelState {
  ManageRefuelState({
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
class ManageRefuelViewModel {
  ManageRefuelViewModel(
    this._getVehicleById,
    this._saveRefuel,
    this._deleteRefuel,
    this._getRefuelById,
    this._getPreviousRefuel,
    this._saveReceiptPhoto,
    this._deleteReceiptPhoto,
    this._businessRules,
  ) : _state = ValueNotifier(ManageRefuelState()),
      loadCommand = Command<Unit>(),
      saveCommand = Command<Unit>(),
      deleteCommand = Command<Unit>(),
      photoCommand = Command<String>();

  final GetVehicleByIdUseCase _getVehicleById;
  final CreateOrUpdateRefuelUseCase _saveRefuel;
  final DeleteRefuelUseCase _deleteRefuel;
  final GetRefuelByIdUseCase _getRefuelById;
  final GetPreviousRefuelUseCase _getPreviousRefuel;
  final SavePhotoUseCase _saveReceiptPhoto;
  final DeletePhotoUseCase _deleteReceiptPhoto;
  final RefuelBusinessRules _businessRules;

  final ValueNotifier<ManageRefuelState> _state;
  ValueListenable<ManageRefuelState> get state => _state;

  final Command<Unit> loadCommand;
  final Command<Unit> saveCommand;
  final Command<Unit> deleteCommand;
  final Command<String> photoCommand;

  String? _stagedToDeletePhotoPath;
  String? _editingId;
  String? _editingVehicleId;
  DateTime? _editingCreatedAt;
  VehicleEntity? _vehicle;

  bool get isEditing => _editingId != null;

  bool get hasColdStart => _state.value.coldStartLiters != null && _state.value.coldStartValue != null;

  void setColdStart({required bool value}) {
    if (value && !hasColdStart) {
      _state.value = _state.value.copyWith(coldStartLiters: 0.0, coldStartValue: 0.0);
    } else if (!value && hasColdStart) {
      _state.value = _state.value.copyWith(clearColdStart: true);
    }
  }

  bool get hasReceiptPhoto => _state.value.wantsReceiptPhoto || _state.value.receiptPath != null;

  File? get currentReceiptPhoto {
    final path = _state.value.receiptPath;
    return path != null ? File(path) : null;
  }

  void toggleReceiptPhoto({required bool value}) {
    if (value) {
      _state.value = _state.value.copyWith(wantsReceiptPhoto: true);
    } else {
      if (_state.value.receiptPath != null) {
        onRemovePhoto();
      } else {
        _state.value = _state.value.copyWith(wantsReceiptPhoto: false);
      }
    }
  }

  Future<void> init(String? id, String? vehicleId) async {
    if (id != null && id.isNotEmpty) {
      await loadCommand.run(() async {
        final either = await _getRefuelById(id);
        Failure? failure;
        RefuelEntity? refuel;
        either.fold(
          (f) {
            failure = f;
          },
          (r) {
            refuel = r;
          },
        );
        if (failure != null) return Left(failure!);
        if (refuel == null) {
          return const Left(ValidationFailure('Abastecimento não encontrado'));
        }
        final r = refuel!;
        await _loadVehicleData(r.vehicleId);
        _editingId = r.id;
        _editingVehicleId = r.vehicleId;
        _editingCreatedAt = r.createdAt;
        _state.value = _state.value.copyWith(
          mileage: r.mileage,
          totalValue: r.totalValue,
          liters: r.liters,
          coldStartLiters: r.coldStartLiters,
          coldStartValue: r.coldStartValue,
          receiptPath: r.receiptPath,
          wantsReceiptPhoto: r.receiptPath != null,
          refuelDate: r.refuelDate,
          fuelType: r.fuelType,
        );
        return right(unit);
      });
    } else if (vehicleId != null && vehicleId.isNotEmpty) {
      await _initWithVehicle(vehicleId);
    } else {
      loadCommand.state.value = const UiError(
        ValidationFailure('ID do veículo é obrigatório para novo abastecimento.'),
      );
    }
  }

  Future<void> _initWithVehicle(String vehicleId) async {
    await loadCommand.run(() async {
      await _loadVehicleData(vehicleId);
      await _loadPreviousMileage(vehicleId, DateTime.now(), 0);
      return right(unit);
    });
  }

  bool get vehicleHasColdStartReservoir {
    if (_vehicle == null) return false;
    return _businessRules.vehicleHasColdStartReservoir(_vehicle!);
  }

  bool get shouldShowColdStart {
    if (_vehicle == null) return false;
    return _businessRules.shouldShowColdStart(
      vehicle: _vehicle!,
      selectedFuelType: _state.value.fuelType,
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
        previousMileage: _state.value.previousMileage,
      );
    };
  }

  Future<void> _loadVehicleData(String vehicleId) async {
    final vehicleEither = await _getVehicleById(vehicleId);
    vehicleEither.fold(
      (_) {},
      (vehicle) {
        if (vehicle != null) {
          _vehicle = vehicle;
          final availableFuelTypes = _businessRules.getAvailableFuelTypes(vehicle);
          _state.value = _state.value.copyWith(
            availableFuelTypes: availableFuelTypes,
            fuelType: availableFuelTypes.first,
          );
        }
      },
    );
  }

  Future<void> _loadPreviousMileage(String vehicleId, DateTime createdAt, int mileage) async {
    final previousEither = await _getPreviousRefuel(vehicleId, createdAt, mileage);
    previousEither.fold(
      (_) {},
      (previousRefuel) {
        if (previousRefuel != null) {
          _state.value = _state.value.copyWith(previousMileage: previousRefuel.mileage);
        }
      },
    );
  }

  RefuelEntity _buildEntity() {
    final s = _state.value;
    final editing = _editingId != null;
    return RefuelEntity(
      id: editing ? _editingId! : UuidHelper.generate(),
      vehicleId: _editingVehicleId ?? _vehicle?.id ?? '',
      mileage: s.mileage,
      totalValue: s.totalValue,
      liters: s.liters,
      coldStartLiters: s.coldStartLiters,
      coldStartValue: s.coldStartValue,
      receiptPath: s.receiptPath,
      refuelDate: s.refuelDate,
      fuelType: s.fuelType,
      createdAt: editing ? _editingCreatedAt! : DateTime.now(),
      updatedAt: editing ? DateTime.now() : null,
    );
  }

  Future<Either<Failure, Unit>?> save() async {
    final result = await saveCommand.run(() => _saveRefuel(_buildEntity()));
    if (result?.isRight == true) _cleanupStagedPhoto();
    return result;
  }

  Future<Either<Failure, Unit>?> delete() async {
    if (_editingId == null) {
      return const Left(
        ValidationFailure('Não é possível excluir um abastecimento que não foi salvo.'),
      );
    }
    return deleteCommand.run(() => _deleteRefuel(_editingId!));
  }

  Future<void> onPickLocalPhoto(File file) async {
    final result = await photoCommand.run(
      () => _saveReceiptPhoto(file: file, oldPath: _state.value.receiptPath),
    );
    result?.fold(
      (_) {},
      (newPath) {
        _stagedToDeletePhotoPath = null;
        _state.value = _state.value.copyWith(receiptPath: newPath, wantsReceiptPhoto: true);
      },
    );
  }

  void onRemovePhoto() {
    _stagedToDeletePhotoPath = _state.value.receiptPath;
    _state.value = _state.value.copyWith(clearPhotoPath: true);
  }

  void _cleanupStagedPhoto() {
    final toDelete = _stagedToDeletePhotoPath;
    if (toDelete != null && toDelete.isNotEmpty) {
      _deleteReceiptPhoto(toDelete).ignore();
      _stagedToDeletePhotoPath = null;
    }
  }

  void updateRefuelDate(DateTime date) => _state.value = _state.value.copyWith(refuelDate: date);

  void updateMileage(String value) => _state.value = _state.value.copyWith(mileage: NumericParser.parseInt(value));

  void updateTotalValue(String value) =>
      _state.value = _state.value.copyWith(totalValue: NumericParser.parseDouble(value));

  void updateLiters(String value) => _state.value = _state.value.copyWith(liters: NumericParser.parseDouble(value));

  void updateColdStartLiters(String value) =>
      _state.value = _state.value.copyWith(coldStartLiters: NumericParser.parseDouble(value));

  void updateColdStartValue(String value) =>
      _state.value = _state.value.copyWith(coldStartValue: NumericParser.parseDouble(value));

  void updateFuelType(FuelType value) => _state.value = _state.value.copyWith(fuelType: value);

  void dispose() {
    _state.dispose();
    loadCommand.dispose();
    saveCommand.dispose();
    deleteCommand.dispose();
    photoCommand.dispose();
  }
}

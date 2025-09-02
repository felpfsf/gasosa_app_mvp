import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/application/commands/photos/delete_photo_command.dart';
import 'package:gasosa_app/application/commands/photos/save_photo_command.dart';
import 'package:gasosa_app/application/commands/refuel/create_or_update_refuel_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/helpers/uuid.dart';
import 'package:gasosa_app/core/viewmodel/base_viewmodel.dart';
import 'package:gasosa_app/core/viewmodel/loading_controller.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:gasosa_app/domain/repositories/refuel_repository.dart';

class ManageRefuelState {
  ManageRefuelState({
    this.isLoading = false,
    this.errorMessage,
    this.initial,
    this.isEditing = false,
    this.mileage = 0,
    this.totalValue = 0.0,
    this.liters = 0.0,
    this.coldStartLiters,
    this.coldStartValue,
    this.receiptPath,
    this.fuelType = FuelType.gasoline,
    DateTime? refuelDate,
  }) : refuelDate = refuelDate ?? DateTime.now();

  final bool isLoading;
  final String? errorMessage;
  final RefuelEntity? initial;
  final bool isEditing;
  final int mileage;
  final double totalValue;
  final double liters;
  final double? coldStartLiters;
  final double? coldStartValue;
  final String? receiptPath;
  final DateTime refuelDate;
  final FuelType fuelType;

  ManageRefuelState copyWith({
    bool? isLoading,
    String? errorMessage,
    RefuelEntity? initial,
    bool? isEditing,
    int? mileage,
    double? totalValue,
    double? liters,
    double? coldStartLiters,
    double? coldStartValue,
    String? receiptPath,
    DateTime? refuelDate,
    FuelType? fuelType,
    bool clearPhotoPath = false,
  }) {
    return ManageRefuelState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      initial: initial ?? this.initial,
      isEditing: isEditing ?? this.isEditing,
      mileage: mileage ?? this.mileage,
      totalValue: totalValue ?? this.totalValue,
      liters: liters ?? this.liters,
      coldStartLiters: coldStartLiters ?? this.coldStartLiters,
      coldStartValue: coldStartValue ?? this.coldStartValue,
      receiptPath: clearPhotoPath ? null : (receiptPath ?? this.receiptPath),
      refuelDate: refuelDate ?? this.refuelDate,
      fuelType: fuelType ?? this.fuelType,
    );
  }
}

class ManageRefuelViewmodel extends BaseViewModel {
  ManageRefuelViewmodel({
    required RefuelRepository repository,
    required LoadingController loading,
    required CreateOrUpdateRefuelCommand saveRefuel,
    required SavePhotoCommand saveReceiptPhoto,
    required DeletePhotoCommand deleteReceiptPhoto,
  }) : _repository = repository,
       _saveRefuel = saveRefuel,
       _saveReceiptPhoto = saveReceiptPhoto,
       _deleteReceiptPhoto = deleteReceiptPhoto,
       super(loading);

  final RefuelRepository _repository;
  final CreateOrUpdateRefuelCommand _saveRefuel;
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

  Future<void> init(String? id) async {
    if (id != null && id.isNotEmpty) {
      setViewLoading(value: true);
      final either = await _repository.getRefuelById(id);
      either.fold(
        _setFailure,
        (refuel) {
          if (refuel == null) {
            _setFailure(const BusinessFailure('Abastecimento não encontrado'));
            return;
          }

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

          notifyListeners();
        },
      );
    }
  }

  RefuelEntity _buildEntity() {
    final isEditing = state.isEditing && state.initial != null;

    return RefuelEntity(
      id: isEditing ? state.initial!.id : UuidHelper.generate(),
      vehicleId: state.initial?.vehicleId ?? '',
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

  void updateMileage(String value) {
    final parsed = int.tryParse(value.trim()) ?? 0;
    _state = _state.copyWith(mileage: parsed);
    notifyListeners();
  }

  void updateTotalValue(String value) {
    final parsed = double.tryParse(value.trim()) ?? 0;
    _state = _state.copyWith(totalValue: parsed);
    notifyListeners();
  }

  void updateLiters(String value) {
    final parsed = double.tryParse(value.trim()) ?? 0;
    _state = _state.copyWith(liters: parsed);
    notifyListeners();
  }

  void updateColdStartLiters(String value) {
    final parsed = double.tryParse(value.trim()) ?? 0;
    _state = _state.copyWith(coldStartLiters: parsed);
    notifyListeners();
  }

  void updateColdStartValue(String value) {
    final parsed = double.tryParse(value.trim()) ?? 0;
    _state = _state.copyWith(coldStartValue: parsed);
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

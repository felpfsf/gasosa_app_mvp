import 'dart:io';

import 'package:gasosa_app/application/photos/delete_photo_use_case.dart';
import 'package:gasosa_app/application/photos/save_photo_use_case.dart';
import 'package:gasosa_app/application/refuel/create_or_update_refuel_use_case.dart';
import 'package:gasosa_app/application/refuel/delete_refuel_use_case.dart';
import 'package:gasosa_app/application/refuel/get_previous_refuel_use_case.dart';
import 'package:gasosa_app/application/refuel/get_refuel_by_id_use_case.dart';
import 'package:gasosa_app/application/vehicles/create_or_update_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/delete_vehicle_use_case.dart';
import 'package:gasosa_app/application/vehicles/get_vehicle_by_id_use_case.dart';
import 'package:mocktail/mocktail.dart';

import 'factories/refuel_factory.dart';
import 'factories/vehicle_factory.dart';

// ─── Vehicle use cases ────────────────────────────────────────────────────────

class MockGetVehicleByIdUseCase extends Mock implements GetVehicleByIdUseCase {}

class MockCreateOrUpdateVehicleUseCase extends Mock implements CreateOrUpdateVehicleUseCase {}

class MockDeleteVehicleUseCase extends Mock implements DeleteVehicleUseCase {}

// ─── Refuel use cases ─────────────────────────────────────────────────────────

class MockGetRefuelByIdUseCase extends Mock implements GetRefuelByIdUseCase {}

class MockCreateOrUpdateRefuelUseCase extends Mock implements CreateOrUpdateRefuelUseCase {}

class MockDeleteRefuelUseCase extends Mock implements DeleteRefuelUseCase {}

class MockGetPreviousRefuelUseCase extends Mock implements GetPreviousRefuelUseCase {}

// ─── Photo use cases ──────────────────────────────────────────────────────────

class MockSavePhotoUseCase extends Mock implements SavePhotoUseCase {}

class MockDeletePhotoUseCase extends Mock implements DeletePhotoUseCase {}

// ─── Fallback values ──────────────────────────────────────────────────────────

void registerViewModelFallbacks() {
  registerFallbackValue(VehicleFactory.create());
  registerFallbackValue(RefuelFactory.create());
  registerFallbackValue(File(''));
  registerFallbackValue(DateTime.now());
}

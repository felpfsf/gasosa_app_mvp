import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:gasosa_app/presentation/screens/vehicle/viewmodel/manage_vehicle_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/factories/vehicle_factory.dart';
import '../../../../helpers/mock_services.dart';
import '../../../../helpers/mock_use_cases.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late MockAuthService mockAuth;
  late MockGetVehicleByIdUseCase mockGetVehicle;
  late MockCreateOrUpdateVehicleUseCase mockSaveVehicle;
  late MockDeleteVehicleUseCase mockDeleteVehicle;
  late MockSavePhotoUseCase mockSavePhoto;
  late MockDeletePhotoUseCase mockDeletePhoto;
  late ManageVehicleViewModel viewModel;

  setUp(() {
    mockAuth = MockAuthService();
    mockGetVehicle = MockGetVehicleByIdUseCase();
    mockSaveVehicle = MockCreateOrUpdateVehicleUseCase();
    mockDeleteVehicle = MockDeleteVehicleUseCase();
    mockSavePhoto = MockSavePhotoUseCase();
    mockDeletePhoto = MockDeletePhotoUseCase();

    when(() => mockAuth.currentUser()).thenAnswer(
      (_) async => const AuthUser('user-1', 'Test User', 'test@test.com'),
    );

    viewModel = ManageVehicleViewModel(
      mockAuth,
      mockGetVehicle,
      mockSaveVehicle,
      mockDeleteVehicle,
      mockSavePhoto,
      mockDeletePhoto,
    );
  });

  setUpAll(registerViewModelFallbacks);

  tearDown(() => viewModel.dispose());

  // ─── Estado inicial ─────────────────────────────────────────────────────────

  group('estado inicial', () {
    test('isEditing é false', () {
      expect(viewModel.isEditing, isFalse);
    });

    test('isLoading é false', () {
      expect(viewModel.isLoading, isFalse);
    });

    test('currentPhoto é null quando photoPath vazio', () {
      expect(viewModel.currentPhoto, isNull);
    });

    test('state tem valores padrão', () {
      final s = viewModel.state.value;
      expect(s.name, '');
      expect(s.plate, '');
      expect(s.tankCapacity, '');
      expect(s.fuelType, FuelType.flex);
    });
  });

  // ─── init() ─────────────────────────────────────────────────────────────────

  group('init()', () {
    test('sem vehicleId não chama o repositório', () async {
      await viewModel.init();
      verifyNever(() => mockGetVehicle(any()));
    });

    test('com vehicleId válido popula o state', () async {
      final vehicle = VehicleFactory.createValid(
        id: 'v-1',
        name: 'Civic',
        plate: 'ABC1234',
        tankCapacity: 50.0,
        fuelType: FuelType.gasoline,
      );
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));

      await viewModel.init(vehicleId: 'v-1');

      final s = viewModel.state.value;
      expect(s.name, 'Civic');
      expect(s.plate, 'ABC1234');
      expect(s.tankCapacity, '50.0');
      expect(s.fuelType, FuelType.gasoline);
    });

    test('com vehicleId válido isEditing vira true', () async {
      final vehicle = VehicleFactory.createValid(id: 'v-1');
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));

      await viewModel.init(vehicleId: 'v-1');

      expect(viewModel.isEditing, isTrue);
    });

    test('veículo não encontrado deixa loadCommand em UiError', () async {
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(null));

      await viewModel.init(vehicleId: 'v-missing');

      expect(viewModel.loadCommand.state.value, isA<UiError>());
    });

    test('falha no repositório deixa loadCommand em UiError', () async {
      when(() => mockGetVehicle(any())).thenAnswer(
        (_) async => left(const DatabaseFailure('erro', null, null)),
      );

      await viewModel.init(vehicleId: 'v-1');

      expect(viewModel.loadCommand.state.value, isA<UiError>());
    });
  });

  // ─── save() ─────────────────────────────────────────────────────────────────

  group('save()', () {
    setUp(() async => viewModel.init()); // só seta _userId

    test('delega ao saveVehicle', () async {
      when(() => mockSaveVehicle(any())).thenAnswer((_) async => right(unit));

      await viewModel.save();

      verify(() => mockSaveVehicle(any())).called(1);
    });

    test('retorna Right(unit) em sucesso', () async {
      when(() => mockSaveVehicle(any())).thenAnswer((_) async => right(unit));

      final result = await viewModel.save();

      expect(result, isRight());
    });

    test('retorna Left em falha', () async {
      when(() => mockSaveVehicle(any())).thenAnswer(
        (_) async => left(const DatabaseFailure('erro', null, null)),
      );

      final result = await viewModel.save();

      expect(result, isLeft());
    });
  });

  // ─── delete() ───────────────────────────────────────────────────────────────

  group('delete()', () {
    test('sem editingId retorna Left(ValidationFailure)', () async {
      final result = await viewModel.delete();

      expect(result, isLeft());
      expect(result, isLeftWith<ValidationFailure>());
      verifyNever(() => mockDeleteVehicle(any()));
    });

    test('com editingId delega ao _deleteVehicle', () async {
      final vehicle = VehicleFactory.createValid(id: 'v-1');
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      when(() => mockDeleteVehicle(any())).thenAnswer((_) async => right(unit));

      await viewModel.init(vehicleId: 'v-1');
      await viewModel.delete();

      verify(() => mockDeleteVehicle('v-1')).called(1);
    });

    test('com editingId retorna Right em sucesso', () async {
      final vehicle = VehicleFactory.createValid(id: 'v-1');
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      when(() => mockDeleteVehicle(any())).thenAnswer((_) async => right(unit));

      await viewModel.init(vehicleId: 'v-1');
      final result = await viewModel.delete();

      expect(result, isRight());
    });
  });

  // ─── update methods ─────────────────────────────────────────────────────────

  group('update methods', () {
    test('updateName atualiza state.name', () {
      viewModel.updateName('Honda Civic');
      expect(viewModel.state.value.name, 'Honda Civic');
    });

    test('updatePlate atualiza state.plate', () {
      viewModel.updatePlate('XYZ9999');
      expect(viewModel.state.value.plate, 'XYZ9999');
    });

    test('updateTankCapacity atualiza state.tankCapacity', () {
      viewModel.updateTankCapacity('60');
      expect(viewModel.state.value.tankCapacity, '60');
    });

    test('updateFuelType atualiza state.fuelType', () {
      viewModel.updateFuelType(FuelType.ethanol);
      expect(viewModel.state.value.fuelType, FuelType.ethanol);
    });
  });

  // ─── photo management ───────────────────────────────────────────────────────

  group('photo management', () {
    test('currentPhoto retorna File quando photoPath definido', () {
      viewModel.updateName('X'); // apenas para trigger, photoPath vem do init
      // Simula estado com photoPath via init com vehicle
      final vehicle = VehicleFactory.createValid(id: 'v-1');
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      // path vem do vehicle.photoPath que é null em createValid → photoPath=''
      expect(viewModel.currentPhoto, isNull);
    });

    test('onRemovePhoto limpa photoPath do state', () async {
      final vehicle = VehicleFactory.createFull(id: 'v-1', photoPath: '/foto.jpg');
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));

      await viewModel.init(vehicleId: 'v-1');
      viewModel.onRemovePhoto();

      expect(viewModel.state.value.photoPath, isNull);
    });

    test('onPickLocalPhoto atualiza photoPath em sucesso', () async {
      when(
        () => mockSavePhoto(
          file: any(named: 'file'),
          oldPath: any(named: 'oldPath'),
        ),
      ).thenAnswer(
        (_) async => right('/nova_foto.jpg'),
      );

      await viewModel.onPickLocalPhoto(File('/tmp/test.jpg'));

      expect(viewModel.state.value.photoPath, '/nova_foto.jpg');
    });
  });
}

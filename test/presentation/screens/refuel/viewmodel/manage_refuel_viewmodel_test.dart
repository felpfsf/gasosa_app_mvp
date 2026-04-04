import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/services/refuel_business_rules.dart';
import 'package:gasosa_app/presentation/screens/refuel/viewmodel/manage_refuel_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/factories/refuel_factory.dart';
import '../../../../helpers/factories/vehicle_factory.dart';
import '../../../../helpers/mock_use_cases.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late MockGetVehicleByIdUseCase mockGetVehicle;
  late MockCreateOrUpdateRefuelUseCase mockSaveRefuel;
  late MockDeleteRefuelUseCase mockDeleteRefuel;
  late MockGetRefuelByIdUseCase mockGetRefuelById;
  late MockGetPreviousRefuelUseCase mockGetPreviousRefuel;
  late MockSavePhotoUseCase mockSavePhoto;
  late MockDeletePhotoUseCase mockDeletePhoto;
  late ManageRefuelViewModel viewModel;

  final vehicle = VehicleFactory.createValid(id: 'v-1');

  setUp(() {
    mockGetVehicle = MockGetVehicleByIdUseCase();
    mockSaveRefuel = MockCreateOrUpdateRefuelUseCase();
    mockDeleteRefuel = MockDeleteRefuelUseCase();
    mockGetRefuelById = MockGetRefuelByIdUseCase();
    mockGetPreviousRefuel = MockGetPreviousRefuelUseCase();
    mockSavePhoto = MockSavePhotoUseCase();
    mockDeletePhoto = MockDeletePhotoUseCase();

    viewModel = ManageRefuelViewModel(
      mockGetVehicle,
      mockSaveRefuel,
      mockDeleteRefuel,
      mockGetRefuelById,
      mockGetPreviousRefuel,
      mockSavePhoto,
      mockDeletePhoto,
      const RefuelBusinessRules(),
    );
  });

  setUpAll(registerViewModelFallbacks);

  tearDown(() => viewModel.dispose());

  // ─── Estado inicial ─────────────────────────────────────────────────────────

  group('estado inicial', () {
    test('isEditing é false', () {
      expect(viewModel.isEditing, isFalse);
    });

    test('hasColdStart é false', () {
      expect(viewModel.hasColdStart, isFalse);
    });

    test('hasReceiptPhoto é false', () {
      expect(viewModel.hasReceiptPhoto, isFalse);
    });

    test('currentReceiptPhoto é null', () {
      expect(viewModel.currentReceiptPhoto, isNull);
    });

    test('state tem fuelType padrão gasoline', () {
      expect(viewModel.state.value.fuelType, FuelType.gasoline);
    });
  });

  // ─── setColdStart ────────────────────────────────────────────────────────────

  group('setColdStart', () {
    test('setColdStart(true) inicializa coldStartLiters e coldStartValue a 0.0', () {
      viewModel.setColdStart(value: true);

      expect(viewModel.state.value.coldStartLiters, 0.0);
      expect(viewModel.state.value.coldStartValue, 0.0);
      expect(viewModel.hasColdStart, isTrue);
    });

    test('setColdStart(false) quando tem cold start limpa os valores', () {
      viewModel.setColdStart(value: true);
      viewModel.setColdStart(value: false);

      expect(viewModel.state.value.coldStartLiters, isNull);
      expect(viewModel.state.value.coldStartValue, isNull);
      expect(viewModel.hasColdStart, isFalse);
    });

    test('setColdStart(true) quando já tem cold start não altera o state', () {
      viewModel.setColdStart(value: true);
      viewModel.updateColdStartLiters('2.5');
      viewModel.setColdStart(value: true); // no-op

      expect(viewModel.state.value.coldStartLiters, 2.5);
    });

    test('setColdStart(false) quando já não tem cold start não altera o state', () {
      final stateBefore = viewModel.state.value;
      viewModel.setColdStart(value: false); // no-op

      expect(viewModel.state.value, same(stateBefore));
    });
  });

  // ─── toggleReceiptPhoto ──────────────────────────────────────────────────────

  group('toggleReceiptPhoto', () {
    test('toggleReceiptPhoto(true) define wantsReceiptPhoto como true', () {
      viewModel.toggleReceiptPhoto(value: true);

      expect(viewModel.state.value.wantsReceiptPhoto, isTrue);
      expect(viewModel.hasReceiptPhoto, isTrue);
    });

    test('toggleReceiptPhoto(false) sem receiptPath define wantsReceiptPhoto como false', () {
      viewModel.toggleReceiptPhoto(value: true);
      viewModel.toggleReceiptPhoto(value: false);

      expect(viewModel.state.value.wantsReceiptPhoto, isFalse);
      expect(viewModel.hasReceiptPhoto, isFalse);
    });

    test('toggleReceiptPhoto(false) com receiptPath chama onRemovePhoto (limpa o path)', () {
      // Simula estado com receiptPath
      when(
        () => mockSavePhoto(
          file: any(named: 'file'),
          oldPath: any(named: 'oldPath'),
        ),
      ).thenAnswer((_) async => right('/receipt.jpg'));

      viewModel.toggleReceiptPhoto(value: false);
      // Se não havia path (estado inicial), apenas reseta wantsReceiptPhoto
      expect(viewModel.state.value.receiptPath, isNull);
    });
  });

  // ─── init() ─────────────────────────────────────────────────────────────────

  group('init()', () {
    test('sem id nem vehicleId deixa loadCommand em UiError', () async {
      await viewModel.init(null, null);

      expect(viewModel.loadCommand.state.value, isA<UiError>());
    });

    test('com vehicleId válido carrega availableFuelTypes do veículo', () async {
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      when(() => mockGetPreviousRefuel(any(), any(), any())).thenAnswer((_) async => right(null));

      await viewModel.init(null, 'v-1');

      expect(viewModel.state.value.availableFuelTypes, [FuelType.gasoline]);
      expect(viewModel.loadCommand.state.value, isA<UiData>());
    });

    test('com refuel id válido isEditing vira true e popula o state', () async {
      final refuel = RefuelFactory.createValid(
        id: 'r-1',
        vehicleId: 'v-1',
        mileage: 55000,
        totalValue: 300.0,
        liters: 40.0,
      );
      when(() => mockGetRefuelById(any())).thenAnswer((_) async => right(refuel));
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      when(() => mockGetPreviousRefuel(any(), any(), any())).thenAnswer((_) async => right(null));

      await viewModel.init('r-1', null);

      expect(viewModel.isEditing, isTrue);
      expect(viewModel.state.value.mileage, 55000);
      expect(viewModel.state.value.totalValue, 300.0);
      expect(viewModel.state.value.liters, 40.0);
    });

    test('com refuel id não encontrado deixa loadCommand em UiError', () async {
      when(() => mockGetRefuelById(any())).thenAnswer((_) async => right(null));

      await viewModel.init('r-inexistente', null);

      expect(viewModel.loadCommand.state.value, isA<UiError>());
      expect(viewModel.isEditing, isFalse);
    });

    test('com refuel id e falha no repositório deixa loadCommand em UiError', () async {
      when(() => mockGetRefuelById(any())).thenAnswer(
        (_) async => left(const DatabaseFailure('erro', null, null)),
      );

      await viewModel.init('r-erro', null);

      expect(viewModel.loadCommand.state.value, isA<UiError>());
    });

    test('previousMileage populado quando existe abastecimento anterior', () async {
      final previousRefuel = RefuelFactory.createValid(
        id: 'r-prev',
        vehicleId: 'v-1',
        mileage: 49000,
      );
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      when(() => mockGetPreviousRefuel(any(), any(), any())).thenAnswer(
        (_) async => right(previousRefuel),
      );

      await viewModel.init(null, 'v-1');

      expect(viewModel.state.value.previousMileage, 49000);
    });
  });

  // ─── delete() ───────────────────────────────────────────────────────────────

  group('delete()', () {
    test('sem editingId retorna Left(ValidationFailure)', () async {
      final result = await viewModel.delete();

      expect(result, isLeft());
      expect(result, isLeftWith<ValidationFailure>());
      verifyNever(() => mockDeleteRefuel(any()));
    });

    test('com editingId delega ao _deleteRefuel', () async {
      final refuel = RefuelFactory.createValid(id: 'r-1', vehicleId: 'v-1');
      when(() => mockGetRefuelById(any())).thenAnswer((_) async => right(refuel));
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      when(() => mockGetPreviousRefuel(any(), any(), any())).thenAnswer((_) async => right(null));
      when(() => mockDeleteRefuel(any())).thenAnswer((_) async => right(unit));

      await viewModel.init('r-1', null);
      await viewModel.delete();

      verify(() => mockDeleteRefuel('r-1')).called(1);
    });

    test('com editingId retorna Right em sucesso', () async {
      final refuel = RefuelFactory.createValid(id: 'r-1', vehicleId: 'v-1');
      when(() => mockGetRefuelById(any())).thenAnswer((_) async => right(refuel));
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      when(() => mockGetPreviousRefuel(any(), any(), any())).thenAnswer((_) async => right(null));
      when(() => mockDeleteRefuel(any())).thenAnswer((_) async => right(unit));

      await viewModel.init('r-1', null);
      final result = await viewModel.delete();

      expect(result, isRight());
    });
  });

  // ─── save() ─────────────────────────────────────────────────────────────────

  group('save()', () {
    setUp(() async {
      when(() => mockGetVehicle(any())).thenAnswer((_) async => right(vehicle));
      when(() => mockGetPreviousRefuel(any(), any(), any())).thenAnswer((_) async => right(null));
      await viewModel.init(null, 'v-1');
    });

    test('delega ao saveRefuel', () async {
      when(() => mockSaveRefuel(any())).thenAnswer((_) async => right(unit));

      await viewModel.save();

      verify(() => mockSaveRefuel(any())).called(1);
    });

    test('retorna Right em sucesso', () async {
      when(() => mockSaveRefuel(any())).thenAnswer((_) async => right(unit));

      final result = await viewModel.save();

      expect(result, isRight());
    });

    test('retorna Left em falha', () async {
      when(() => mockSaveRefuel(any())).thenAnswer(
        (_) async => left(const DatabaseFailure('erro', null, null)),
      );

      final result = await viewModel.save();

      expect(result, isLeft());
    });
  });

  // ─── update methods ─────────────────────────────────────────────────────────

  group('update methods', () {
    test('updateMileage atualiza state.mileage', () {
      viewModel.updateMileage('52000');
      expect(viewModel.state.value.mileage, 52000);
    });

    test('updateTotalValue atualiza state.totalValue', () {
      viewModel.updateTotalValue('199.90');
      expect(viewModel.state.value.totalValue, closeTo(199.90, 0.01));
    });

    test('updateLiters atualiza state.liters', () {
      viewModel.updateLiters('35.5');
      expect(viewModel.state.value.liters, closeTo(35.5, 0.01));
    });

    test('updateFuelType atualiza state.fuelType', () {
      viewModel.updateFuelType(FuelType.ethanol);
      expect(viewModel.state.value.fuelType, FuelType.ethanol);
    });

    test('updateRefuelDate atualiza state.refuelDate', () {
      final date = DateTime(2025, 6, 15);
      viewModel.updateRefuelDate(date);
      expect(viewModel.state.value.refuelDate, date);
    });

    test('updateColdStartLiters atualiza state.coldStartLiters', () {
      viewModel.setColdStart(value: true);
      viewModel.updateColdStartLiters('1.5');
      expect(viewModel.state.value.coldStartLiters, closeTo(1.5, 0.01));
    });

    test('updateColdStartValue atualiza state.coldStartValue', () {
      viewModel.setColdStart(value: true);
      viewModel.updateColdStartValue('12.75');
      expect(viewModel.state.value.coldStartValue, closeTo(12.75, 0.01));
    });
  });
}

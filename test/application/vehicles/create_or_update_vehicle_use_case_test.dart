import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/vehicles/create_or_update_vehicle_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/factories/vehicle_factory.dart';
import '../../helpers/mock_repositories.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockVehicleRepository mockRepository;
  late CreateOrUpdateVehicleUseCase command;

  setUp(() {
    mockRepository = MockVehicleRepository();
    command = CreateOrUpdateVehicleUseCase(repository: mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(VehicleFactory.create());
  });

  group('CreateOrUpdateVehicleUseCase -', () {
    group('Criar novo veículo', () {
      test('deve chamar upsertVehicle quando entity.id está vazio', () async {
        // Arrange
        final newVehicle = VehicleFactory.createNew();
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(newVehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.upsertVehicle(newVehicle)).called(1);
      });

      test('deve retornar Right(unit) quando criar com sucesso', () async {
        // Arrange
        final newVehicle = VehicleFactory.createNew();
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(newVehicle);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando criar falhar', () async {
        // Arrange
        final newVehicle = VehicleFactory.createNew();
        const failure = DatabaseFailure('Erro ao salvar veículo', null, null);
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => left(failure));

        // Act
        final result = await command(newVehicle);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao salvar veículo');
      });

      test('deve criar veículo com dados mínimos obrigatórios', () async {
        // Arrange
        final minimalVehicle = VehicleFactory.createMinimal();
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(minimalVehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.upsertVehicle(minimalVehicle)).called(1);
      });

      test('deve criar veículo com todos os campos opcionais preenchidos', () async {
        // Arrange
        final fullVehicle = VehicleFactory.createFull();
        final newFullVehicle = fullVehicle.copyWith(id: '');
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(newFullVehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.upsertVehicle(newFullVehicle)).called(1);
      });
    });

    group('Atualizar veículo existente', () {
      test('deve chamar upsertVehicle quando entity.id não está vazio', () async {
        // Arrange
        final existingVehicle = VehicleFactory.create();
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(existingVehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.upsertVehicle(existingVehicle)).called(1);
      });

      test('deve retornar Right(unit) quando atualizar com sucesso', () async {
        // Arrange
        final existingVehicle = VehicleFactory.create();
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(existingVehicle);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando atualizar falhar', () async {
        // Arrange
        final existingVehicle = VehicleFactory.create();
        const failure = DatabaseFailure('Erro ao atualizar veículo', null, null);
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => left(failure));

        // Act
        final result = await command(existingVehicle);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao atualizar veículo');
      });

      test('deve atualizar veículo com mudança de placa', () async {
        // Arrange
        final vehicle = VehicleFactory.create();
        final updatedVehicle = vehicle.copyWith(plate: 'XYZ9876');
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(updatedVehicle);

        // Assert
        expect(result, isRight());
        final captured = verify(() => mockRepository.upsertVehicle(captureAny())).captured.first as VehicleEntity;
        expect(captured.plate, 'XYZ9876');
      });

      test('deve atualizar veículo removendo foto (photoPath vazio)', () async {
        // Arrange
        final vehicle = VehicleFactory.create();
        final withoutPhoto = vehicle.copyWith(photoPath: '');
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(withoutPhoto);

        // Assert
        expect(result, isRight());
        final captured = verify(() => mockRepository.upsertVehicle(captureAny())).captured.first as VehicleEntity;
        expect(captured.photoPath, isEmpty);
      });
    });

    group('Validação de comportamento', () {
      test('deve preservar timestamps ao criar', () async {
        // Arrange
        final vehicle = VehicleFactory.createNew();
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        await command(vehicle);

        // Assert
        final captured = verify(() => mockRepository.upsertVehicle(captureAny())).captured.first as VehicleEntity;
        expect(captured.createdAt, vehicle.createdAt);
        expect(captured.updatedAt, vehicle.updatedAt);
      });

      test('deve delegar para repository sem lógica adicional', () async {
        // Arrange
        final vehicle = VehicleFactory.create();
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        await command(vehicle);

        // Assert
        verify(() => mockRepository.upsertVehicle(vehicle)).called(1);
      });
    });

    group('Edge cases', () {
      test('deve tratar veículo com tankCapacity = 0', () async {
        // Arrange
        final vehicle = VehicleFactory.create().copyWith(tankCapacity: 0.0);
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(vehicle);

        // Assert
        expect(result, isRight());
        final captured = verify(() => mockRepository.upsertVehicle(captureAny())).captured.first as VehicleEntity;
        expect(captured.tankCapacity, 0.0);
      });

      test('deve criar múltiplos veículos sequencialmente', () async {
        // Arrange
        final vehicles = VehicleFactory.createList(3);
        when(() => mockRepository.upsertVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final results = await Future.wait(
          vehicles.map((v) => command(v.copyWith(id: ''))),
        );

        // Assert
        expect(results.every((r) => r.isRight), true);
        verify(() => mockRepository.upsertVehicle(any())).called(3);
      });
    });
  });
}

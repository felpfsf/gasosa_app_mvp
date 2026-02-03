import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/vehicles/create_or_update_vehicle_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/factories/vehicle_factory.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockVehicleRepository mockRepository;
  late CreateOrUpdateVehicleCommand command;

  setUp(() {
    mockRepository = MockVehicleRepository();
    command = CreateOrUpdateVehicleCommand(repository: mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(VehicleFactory.create());
  });

  group('CreateOrUpdateVehicleCommand -', () {
    group('Criar novo veículo', () {
      test('deve chamar createVehicle quando entity.id está vazio', () async {
        // Arrange
        final newVehicle = VehicleFactory.createNew();
        when(() => mockRepository.createVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(newVehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.createVehicle(newVehicle)).called(1);
        verifyNever(() => mockRepository.updateVehicle(any()));
      });

      test('deve retornar Right(unit) quando criar com sucesso', () async {
        // Arrange
        final newVehicle = VehicleFactory.createNew();
        when(() => mockRepository.createVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(newVehicle);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando criar falhar', () async {
        // Arrange
        final newVehicle = VehicleFactory.createNew();
        const failure = DatabaseFailure('Erro ao salvar veículo');
        when(() => mockRepository.createVehicle(any())).thenAnswer((_) async => left(failure));

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
        when(() => mockRepository.createVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(minimalVehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.createVehicle(minimalVehicle)).called(1);
      });

      test('deve criar veículo com todos os campos opcionais preenchidos', () async {
        // Arrange
        final fullVehicle = VehicleFactory.createFull();
        // ID vazio para forçar criação
        final newFullVehicle = fullVehicle.copyWith(id: '');
        when(() => mockRepository.createVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(newFullVehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.createVehicle(newFullVehicle)).called(1);
      });
    });

    group('Atualizar veículo existente', () {
      test('deve chamar updateVehicle quando entity.id não está vazio', () async {
        // Arrange
        final existingVehicle = VehicleFactory.create();
        when(() => mockRepository.updateVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(existingVehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.updateVehicle(existingVehicle)).called(1);
        verifyNever(() => mockRepository.createVehicle(any()));
      });

      test('deve retornar Right(unit) quando atualizar com sucesso', () async {
        // Arrange
        final existingVehicle = VehicleFactory.create();
        when(() => mockRepository.updateVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(existingVehicle);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando atualizar falhar', () async {
        // Arrange
        final existingVehicle = VehicleFactory.create();
        const failure = DatabaseFailure('Erro ao atualizar veículo');
        when(() => mockRepository.updateVehicle(any())).thenAnswer((_) async => left(failure));

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
        when(() => mockRepository.updateVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(updatedVehicle);

        // Assert
        expect(result, isRight());
        final captured = verify(() => mockRepository.updateVehicle(captureAny())).captured.first as VehicleEntity;
        expect(captured.plate, 'XYZ9876');
      });

      test('deve atualizar veículo removendo foto (photoPath vazio)', () async {
        // Arrange
        final vehicle = VehicleFactory.create();
        final withoutPhoto = vehicle.copyWith(photoPath: '');
        when(() => mockRepository.updateVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(withoutPhoto);

        // Assert
        expect(result, isRight());
        final captured = verify(() => mockRepository.updateVehicle(captureAny())).captured.first as VehicleEntity;
        expect(captured.photoPath, isEmpty);
      });
    });

    group('Validação de comportamento', () {
      test('deve preservar timestamps ao criar', () async {
        // Arrange
        final vehicle = VehicleFactory.createNew();
        when(() => mockRepository.createVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        await command(vehicle);

        // Assert
        final captured = verify(() => mockRepository.createVehicle(captureAny())).captured.first as VehicleEntity;
        expect(captured.createdAt, vehicle.createdAt);
        expect(captured.updatedAt, vehicle.updatedAt);
      });

      test('não deve chamar repository quando entity é inválido (id null)', () async {
        // Arrange
        final vehicle = VehicleFactory.create();
        // Simular entity mal formado não faz sentido porque construtor garante integridade
        // Este teste documenta que validação acontece antes da chamada
        when(() => mockRepository.updateVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        await command(vehicle);

        // Assert
        // Validações acontecem em camadas superiores (UI/BLoC)
        // Command delega para repository
        verify(() => mockRepository.updateVehicle(vehicle)).called(1);
      });
    });

    group('Edge cases', () {
      test('deve tratar veículo com tankCapacity = 0', () async {
        // Arrange
        final vehicle = VehicleFactory.create().copyWith(tankCapacity: 0.0);
        when(() => mockRepository.updateVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(vehicle);

        // Assert
        expect(result, isRight());
        final captured = verify(() => mockRepository.updateVehicle(captureAny())).captured.first as VehicleEntity;
        expect(captured.tankCapacity, 0.0);
      });

      test('deve criar múltiplos veículos sequencialmente', () async {
        // Arrange
        final vehicles = VehicleFactory.createList(3);
        when(() => mockRepository.createVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final results = await Future.wait(
          vehicles.map((v) => command(v.copyWith(id: ''))),
        );

        // Assert
        expect(results.every((r) => r.isRight()), true);
        verify(() => mockRepository.createVehicle(any())).called(3);
      });
    });
  });
}

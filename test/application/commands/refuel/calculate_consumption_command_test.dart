import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/refuel/calculate_consumption_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/factories/refuel_factory.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockRefuelRepository mockRepository;
  late CalculateConsumptionCommand command;

  setUp(() {
    mockRepository = MockRefuelRepository();
    command = CalculateConsumptionCommand(repository: mockRepository);
  });

  group('CalculateConsumptionCommand -', () {
    test('deve chamar getPreviousByVehicleId com parâmetros corretos', () async {
      // Arrange
      const vehicleId = 'vehicle-123';
      final createdAt = DateTime(2026, 1, 15);
      const mileage = 50000;
      when(
        () => mockRepository.getPreviousByVehicleId(
          vehicleId,
          createdAt: createdAt,
          mileage: mileage,
        ),
      ).thenAnswer((_) async => right<Failure, RefuelEntity?>(null));

      // Act
      final result = await command(vehicleId, createdAt, mileage);

      // Assert
      expect(result, isRight());
      verify(
        () => mockRepository.getPreviousByVehicleId(
          vehicleId,
          createdAt: createdAt,
          mileage: mileage,
        ),
      ).called(1);
    });

    test('deve retornar Right com refuel anterior quando encontrado', () async {
      // Arrange
      const vehicleId = 'vehicle-456';
      final createdAt = DateTime(2026, 2, 1);
      const mileage = 52000;
      final previousRefuel = RefuelFactory.createValid(
        id: 'refuel-prev',
        vehicleId: vehicleId,
        mileage: 51000,
      );
      when(
        () => mockRepository.getPreviousByVehicleId(
          vehicleId,
          createdAt: createdAt,
          mileage: mileage,
        ),
      ).thenAnswer((_) async => right(previousRefuel));

      // Act
      final result = await command(vehicleId, createdAt, mileage);

      // Assert
      expect(result, isRight());
      expect(rightValue(result)?.id, 'refuel-prev');
    });

    test('deve retornar Right(null) quando não houver refuel anterior', () async {
      // Arrange
      const vehicleId = 'vehicle-789';
      final createdAt = DateTime(2026, 2, 5);
      const mileage = 60000;
      when(
        () => mockRepository.getPreviousByVehicleId(
          vehicleId,
          createdAt: createdAt,
          mileage: mileage,
        ),
      ).thenAnswer((_) async => right<Failure, RefuelEntity?>(null));

      // Act
      final result = await command(vehicleId, createdAt, mileage);

      // Assert
      expect(result, isRight());
      expect(rightValue(result), isNull);
    });

    test('deve retornar Left(DatabaseFailure) quando repository falhar', () async {
      // Arrange
      const vehicleId = 'vehicle-error';
      final createdAt = DateTime(2026, 2, 10);
      const mileage = 65000;
      const failure = DatabaseFailure('Erro ao buscar reabastecimento anterior');
      when(
        () => mockRepository.getPreviousByVehicleId(
          vehicleId,
          createdAt: createdAt,
          mileage: mileage,
        ),
      ).thenAnswer((_) async => left(failure));

      // Act
      final result = await command(vehicleId, createdAt, mileage);

      // Assert
      expect(result, isLeft());
      expect(result, isLeftWith<DatabaseFailure>());
      expect(leftFailure(result).message, 'Erro ao buscar reabastecimento anterior');
    });
  });
}

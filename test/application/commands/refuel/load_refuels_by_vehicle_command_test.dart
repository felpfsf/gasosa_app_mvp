import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/refuel/load_refuels_by_vehicle_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/factories/refuel_factory.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockRefuelRepository mockRepository;
  late LoadRefuelsByVehicleCommand command;

  setUp(() {
    mockRepository = MockRefuelRepository();
    command = LoadRefuelsByVehicleCommand(repository: mockRepository);
  });

  group('LoadRefuelsByVehicleCommand -', () {
    test('deve retornar Stream com lista de abastecimentos', () async {
      // Arrange
      const vehicleId = 'vehicle-123';
      final refuels = RefuelFactory.createList(3, vehicleId: vehicleId);
      when(() => mockRepository.watchAllByVehicleId(any())).thenAnswer(
        (_) => Stream.value(right(refuels)),
      );

      // Act
      final stream = command(vehicleId);
      final result = await stream.first;

      // Assert
      expect(result, isRight());
      expect(rightValue(result).length, 3);
      verify(() => mockRepository.watchAllByVehicleId(vehicleId)).called(1);
    });

    test('deve retornar Stream vazia quando não houver abastecimentos', () async {
      // Arrange
      const vehicleId = 'vehicle-empty';
      when(() => mockRepository.watchAllByVehicleId(any())).thenAnswer(
        (_) => Stream.value(right<Failure, List<RefuelEntity>>([])),
      );

      // Act
      final stream = command(vehicleId);
      final result = await stream.first;

      // Assert
      expect(result, isRight());
      expect(rightValue(result), isEmpty);
    });

    test('deve propagar falha do repository', () async {
      // Arrange
      const vehicleId = 'vehicle-error';
      const failure = DatabaseFailure('Erro ao buscar reabastecimentos');
      when(() => mockRepository.watchAllByVehicleId(any())).thenAnswer(
        (_) => Stream.value(left(failure)),
      );

      // Act
      final stream = command(vehicleId);
      final result = await stream.first;

      // Assert
      expect(result, isLeft());
      expect(result, isLeftWith<DatabaseFailure>());
      expect(leftFailure(result).message, 'Erro ao buscar reabastecimentos');
    });

    test('deve passar vehicleId corretamente para repository', () async {
      // Arrange
      const vehicleId = 'vehicle-789';
      when(() => mockRepository.watchAllByVehicleId(any())).thenAnswer(
        (_) => Stream.value(right<Failure, List<RefuelEntity>>([])),
      );

      // Act
      final stream = command(vehicleId);
      await stream.first;

      // Assert
      final captured = verify(() => mockRepository.watchAllByVehicleId(captureAny())).captured.first;
      expect(captured, vehicleId);
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/vehicles/delete_vehicle_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockVehicleRepository mockRepository;
  late DeleteVehicleCommand command;

  setUp(() {
    mockRepository = MockVehicleRepository();
    command = DeleteVehicleCommand(repository: mockRepository);
  });

  group('DeleteVehicleCommand -', () {
    group('Deletar veículo com sucesso', () {
      test('deve chamar deleteVehicle do repository', () async {
        // Arrange
        const vehicleId = 'vehicle-123';
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(vehicleId);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.deleteVehicle(vehicleId)).called(1);
      });

      test('deve retornar Right(unit) quando deletar com sucesso', () async {
        // Arrange
        const vehicleId = 'vehicle-456';
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(vehicleId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve deletar veículo com ID UUID válido', () async {
        // Arrange
        const vehicleId = '550e8400-e29b-41d4-a716-446655440000';
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(vehicleId);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.deleteVehicle(vehicleId)).called(1);
      });
    });

    group('Deletar veículo com falha', () {
      test('deve retornar Left(DatabaseFailure) quando repository falhar', () async {
        // Arrange
        const vehicleId = 'vehicle-999';
        final failure = DatabaseFailure('Erro ao deletar veículo');
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => left(failure));

        // Act
        final result = await command(vehicleId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao deletar veículo');
      });

      test('deve retornar Left(NotFoundFailure) quando veículo não existe', () async {
        // Arrange
        const vehicleId = 'nonexistent-id';
        final failure = NotFoundFailure('Veículo não encontrado');
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => left(failure));

        // Act
        final result = await command(vehicleId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<NotFoundFailure>());
        expect(leftFailure(result).message, 'Veículo não encontrado');
      });

      test('deve retornar Left(BusinessFailure) quando regra de negócio impedir', () async {
        // Arrange
        const vehicleId = 'vehicle-with-refuels';
        final failure = BusinessFailure('Não é possível deletar veículo com abastecimentos');
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => left(failure));

        // Act
        final result = await command(vehicleId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<BusinessFailure>());
        expect(leftFailure(result).message, 'Não é possível deletar veículo com abastecimentos');
      });
    });

    group('Validação de entrada', () {
      test('deve aceitar ID vazio (repository deve validar)', () async {
        // Arrange
        const vehicleId = '';
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(vehicleId);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.deleteVehicle(vehicleId)).called(1);
      });

      test('deve passar ID exatamente como recebido', () async {
        // Arrange
        const vehicleId = '  spaced-id  ';
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        await command(vehicleId);

        // Assert
        final captured = verify(() => mockRepository.deleteVehicle(captureAny())).captured.first;
        expect(captured, '  spaced-id  '); // Command não faz sanitização
      });
    });

    group('Comportamento assíncrono', () {
      test('deve aguardar conclusão da deleção antes de retornar', () async {
        // Arrange
        const vehicleId = 'vehicle-async';
        var deleteCompleted = false;
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async {
          await delay(const Duration(milliseconds: 50));
          deleteCompleted = true;
          return right(unit);
        });

        // Act
        final result = await command(vehicleId);

        // Assert
        expect(result, isRight());
        expect(deleteCompleted, true);
      });

      test('deve deletar múltiplos veículos em paralelo', () async {
        // Arrange
        final vehicleIds = ['v1', 'v2', 'v3'];
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final results = await Future.wait(
          vehicleIds.map((id) => command(id)),
        );

        // Assert
        expect(results.every((r) => r.isRight()), true);
        expect(results.length, 3);
        verify(() => mockRepository.deleteVehicle(any())).called(3);
      });
    });

    group('Edge cases', () {
      test('deve tratar ID muito longo', () async {
        // Arrange
        final longId = 'v' * 1000;
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(longId);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.deleteVehicle(longId)).called(1);
      });

      test('deve tratar caracteres especiais no ID', () async {
        // Arrange
        const specialId = 'vehicle-@#\$%^&*()';
        when(() => mockRepository.deleteVehicle(any())).thenAnswer((_) async => right(unit));

        // Act
        final result = await command(specialId);

        // Assert
        expect(result, isRight());
        verify(() => mockRepository.deleteVehicle(specialId)).called(1);
      });
    });
  });
}

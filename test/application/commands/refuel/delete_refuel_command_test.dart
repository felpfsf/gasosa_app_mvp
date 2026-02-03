import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/refuel/delete_refuel_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockRefuelRepository mockRepository;
  late DeleteRefuelCommand command;

  setUp(() {
    mockRepository = MockRefuelRepository();
    command = DeleteRefuelCommand(repository: mockRepository);
  });

  group('DeleteRefuelCommand -', () {
    test('deve chamar deleteRefuel com id fornecido', () async {
      // Arrange
      const refuelId = 'refuel-123';
      when(() => mockRepository.deleteRefuel(any())).thenAnswer((_) async => right(unit));

      // Act
      final result = await command(refuelId);

      // Assert
      expect(result, isRight());
      verify(() => mockRepository.deleteRefuel(refuelId)).called(1);
    });

    test('deve retornar Right(unit) quando deletar com sucesso', () async {
      // Arrange
      const refuelId = 'refuel-456';
      when(() => mockRepository.deleteRefuel(any())).thenAnswer((_) async => right(unit));

      // Act
      final result = await command(refuelId);

      // Assert
      expect(result, isRight());
      expect(rightValue(result), unit);
    });

    test('deve retornar Left(NotFoundFailure) quando não encontrado', () async {
      // Arrange
      const refuelId = 'refuel-missing';
      const failure = NotFoundFailure('Abastecimento não encontrado');
      when(() => mockRepository.deleteRefuel(any())).thenAnswer((_) async => left(failure));

      // Act
      final result = await command(refuelId);

      // Assert
      expect(result, isLeft());
      expect(result, isLeftWith<NotFoundFailure>());
      expect(leftFailure(result).message, 'Abastecimento não encontrado');
    });

    test('deve retornar Left(DatabaseFailure) quando repository falhar', () async {
      // Arrange
      const refuelId = 'refuel-error';
      const failure = DatabaseFailure('Erro ao deletar reabastecimento');
      when(() => mockRepository.deleteRefuel(any())).thenAnswer((_) async => left(failure));

      // Act
      final result = await command(refuelId);

      // Assert
      expect(result, isLeft());
      expect(result, isLeftWith<DatabaseFailure>());
      expect(leftFailure(result).message, 'Erro ao deletar reabastecimento');
    });
  });
}

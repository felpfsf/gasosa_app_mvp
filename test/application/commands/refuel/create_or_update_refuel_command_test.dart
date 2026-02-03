import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/refuel/create_or_update_refuel_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/factories/refuel_factory.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockRefuelRepository mockRepository;
  late CreateOrUpdateRefuelCommand command;

  setUp(() {
    mockRepository = MockRefuelRepository();
    command = CreateOrUpdateRefuelCommand(repository: mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(RefuelFactory.create());
  });

  group('CreateOrUpdateRefuelCommand -', () {
    test('deve chamar upsertRefuel com entity fornecida', () async {
      // Arrange
      final refuel = RefuelFactory.createNew();
      when(() => mockRepository.upsertRefuel(any())).thenAnswer((_) async => right(unit));

      // Act
      final result = await command(refuel);

      // Assert
      expect(result, isRight());
      verify(() => mockRepository.upsertRefuel(refuel)).called(1);
    });

    test('deve retornar Right(unit) quando salvar com sucesso', () async {
      // Arrange
      final refuel = RefuelFactory.createNew();
      when(() => mockRepository.upsertRefuel(any())).thenAnswer((_) async => right(unit));

      // Act
      final result = await command(refuel);

      // Assert
      expect(result, isRight());
      expect(rightValue(result), unit);
    });

    test('deve retornar Left(DatabaseFailure) quando repository falhar', () async {
      // Arrange
      final refuel = RefuelFactory.createNew();
      const failure = DatabaseFailure('Erro ao salvar reabastecimento');
      when(() => mockRepository.upsertRefuel(any())).thenAnswer((_) async => left(failure));

      // Act
      final result = await command(refuel);

      // Assert
      expect(result, isLeft());
      expect(result, isLeftWith<DatabaseFailure>());
      expect(leftFailure(result).message, 'Erro ao salvar reabastecimento');
    });

    test('deve salvar abastecimento existente (id preenchido)', () async {
      // Arrange
      final refuel = RefuelFactory.create();
      when(() => mockRepository.upsertRefuel(any())).thenAnswer((_) async => right(unit));

      // Act
      final result = await command(refuel);

      // Assert
      expect(result, isRight());
      verify(() => mockRepository.upsertRefuel(refuel)).called(1);
    });

    test('deve preservar receiptPath ao salvar', () async {
      // Arrange
      final refuel = RefuelFactory.createFull();
      when(() => mockRepository.upsertRefuel(any())).thenAnswer((_) async => right(unit));

      // Act
      await command(refuel);

      // Assert
      final captured = verify(() => mockRepository.upsertRefuel(captureAny())).captured.first as RefuelEntity;
      expect(captured.receiptPath, refuel.receiptPath);
    });
  });
}

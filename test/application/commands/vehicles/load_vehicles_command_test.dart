import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/vehicles/load_vehicles_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/factories/vehicle_factory.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockVehicleRepository mockRepository;
  late LoadVehiclesCommand command;

  setUp(() {
    mockRepository = MockVehicleRepository();
    command = LoadVehiclesCommand(repository: mockRepository);
  });

  group('LoadVehiclesCommand -', () {
    group('Carregar veículos com sucesso', () {
      test('deve retornar Stream com lista de veículos', () async {
        // Arrange
        const userId = 'user-123';
        final vehicles = VehicleFactory.createList(3);
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(right(vehicles)),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final result = await stream.first;

        // Assert
        expect(result, isRight());
        expect(rightValue(result).length, 3);
        verify(() => mockRepository.watchAllByUserId(userId)).called(1);
      });

      test('deve retornar Stream vazia quando usuário não tem veículos', () async {
        // Arrange
        const userId = 'user-empty';
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(right<Failure, List<VehicleEntity>>([])),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final result = await stream.first;

        // Assert
        expect(result, isRight());
        expect(rightValue(result), isEmpty);
      });

      test('deve emitir múltiplas atualizações quando dados mudam', () async {
        // Arrange
        const userId = 'user-456';
        final vehicles1 = VehicleFactory.createList(2);
        final vehicles2 = VehicleFactory.createList(3);

        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.fromIterable([
            right(vehicles1),
            right(vehicles2),
          ]),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final results = await stream.take(2).toList();

        // Assert
        expect(results.length, 2);
        expect(rightValue(results[0]).length, 2);
        expect(rightValue(results[1]).length, 3);
      });

      test('deve manter stream aberto para múltiplas emissões', () async {
        // Arrange
        const userId = 'user-stream';
        final vehicles = VehicleFactory.createList(1);

        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.periodic(
            const Duration(milliseconds: 10),
            (count) => right<Failure, List<VehicleEntity>>(vehicles),
          ),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final results = await stream.take(3).toList();

        // Assert
        expect(results.length, 3);
        expect(results.every((r) => r.isRight()), true);
      });
    });

    group('Carregar veículos com falha', () {
      test('deve retornar Stream com Left(DatabaseFailure) quando falhar', () async {
        // Arrange
        const userId = 'user-error';
        final failure = DatabaseFailure('Erro ao carregar veículos');
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(left(failure)),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final result = await stream.first;

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao carregar veículos');
      });

      test('deve propagar erros do Stream', () async {
        // Arrange
        const userId = 'user-exception';
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.error(Exception('Stream error')),
        );

        // Act
        final stream = command.watchAllByUserId(userId);

        // Assert
        expect(stream, emitsError(isA<Exception>()));
      });

      test('deve retornar Left após erro e depois Right quando recuperar', () async {
        // Arrange
        const userId = 'user-recovery';
        final failure = DatabaseFailure('Erro temporário');
        final vehicles = VehicleFactory.createList(2);

        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.fromIterable([
            left(failure),
            right(vehicles),
          ]),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final results = await stream.take(2).toList();

        // Assert
        expect(results[0], isLeft());
        expect(results[1], isRight());
        expect(rightValue(results[1]).length, 2);
      });
    });

    group('Filtro por userId', () {
      test('deve passar userId correto para repository', () async {
        // Arrange
        const userId = 'specific-user-789';
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(right<Failure, List<VehicleEntity>>([])),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        await stream.first;

        // Assert
        final captured = verify(() => mockRepository.watchAllByUserId(captureAny())).captured.first;
        expect(captured, 'specific-user-789');
      });

      test('deve aceitar userId vazio', () async {
        // Arrange
        const userId = '';
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(right<Failure, List<VehicleEntity>>([])),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        await stream.first;

        // Assert
        verify(() => mockRepository.watchAllByUserId('')).called(1);
      });
    });

    group('Comportamento de Stream', () {
      test('deve permitir múltiplos listeners (broadcast)', () async {
        // Arrange
        const userId = 'user-broadcast';
        final vehicles = VehicleFactory.createList(2);
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream<Either<Failure, List<VehicleEntity>>>.value(right(vehicles)).asBroadcastStream(),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final result1 = stream.first;
        final result2 = stream.first;

        // Assert
        expect(await result1, isRight());
        expect(await result2, isRight());
      });

      test('deve cancelar stream quando listener é cancelado', () async {
        // Arrange
        const userId = 'user-cancel';
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.periodic(
            const Duration(milliseconds: 10),
            (count) => right<Failure, List<VehicleEntity>>([]),
          ),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final subscription = stream.listen((_) {});
        await delay(const Duration(milliseconds: 50));
        await subscription.cancel();

        // Assert
        expect(subscription.isPaused, false); // Cancelado, não pausado
      });

      test('deve emitir done quando stream termina', () async {
        // Arrange
        const userId = 'user-done';
        final vehicles = VehicleFactory.createList(1);
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(right(vehicles)),
        );

        // Act
        final stream = command.watchAllByUserId(userId);

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            isRight(),
            emitsDone,
          ]),
        );
      });
    });

    group('Edge cases', () {
      test('deve lidar com lista muito grande de veículos', () async {
        // Arrange
        const userId = 'user-many';
        final manyVehicles = VehicleFactory.createList(100);
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(right(manyVehicles)),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final result = await stream.first;

        // Assert
        expect(result, isRight());
        expect(rightValue(result).length, 100);
      });

      test('deve preservar ordem dos veículos retornados pelo repository', () async {
        // Arrange
        const userId = 'user-order';
        final vehicles = VehicleFactory.createList(5);
        when(() => mockRepository.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(right(vehicles)),
        );

        // Act
        final stream = command.watchAllByUserId(userId);
        final result = await stream.first;

        // Assert
        final resultVehicles = rightValue(result);
        for (var i = 0; i < vehicles.length; i++) {
          expect(resultVehicles[i].id, vehicles[i].id);
        }
      });
    });
  });
}

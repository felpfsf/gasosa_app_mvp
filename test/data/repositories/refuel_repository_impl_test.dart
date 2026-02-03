import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/data/local/dao/refuel_dao.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/mappers/refuel_mapper.dart';
import 'package:gasosa_app/data/repositories/refuel_repository_impl.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/factories/refuel_factory.dart';
import '../../helpers/test_helpers.dart';

class MockRefuelDao extends Mock implements RefuelDao {}

RefuelRow _createRefuelRow(RefuelEntity entity) {
  return RefuelRow(
    id: entity.id,
    vehicleId: entity.vehicleId,
    refuelDate: entity.refuelDate,
    fuelType: entity.fuelType.name,
    totalValue: entity.totalValue,
    mileage: entity.mileage,
    liters: entity.liters,
    coldStartLiters: entity.coldStartLiters,
    coldStartValue: entity.coldStartValue,
    receiptPath: entity.receiptPath,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}

void main() {
  late MockRefuelDao mockDao;
  late RefuelRepositoryImpl repository;

  setUp(() {
    mockDao = MockRefuelDao();
    repository = RefuelRepositoryImpl(mockDao);
  });

  setUpAll(() {
    registerFallbackValue(RefuelFactory.create());
    registerFallbackValue(RefuelMapper.toCompanion(RefuelFactory.create()));
  });

  group('RefuelRepositoryImpl -', () {
    group('upsertRefuel', () {
      test('deve chamar dao.upsert com companion correto', () async {
        // Arrange
        final refuel = RefuelFactory.createNew();
        when(() => mockDao.upsert(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.upsertRefuel(refuel);

        // Assert
        expect(result, isRight());
        verify(() => mockDao.upsert(any(that: isA<RefuelsCompanion>()))).called(1);
      });

      test('deve retornar Right(unit) quando salvar com sucesso', () async {
        // Arrange
        final refuel = RefuelFactory.createNew();
        when(() => mockDao.upsert(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.upsertRefuel(refuel);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        final refuel = RefuelFactory.createNew();
        when(() => mockDao.upsert(any())).thenThrow(Exception('DB error'));

        // Act
        final result = await repository.upsertRefuel(refuel);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao salvar reabastecimento');
      });
    });

    group('deleteRefuel', () {
      test('deve chamar dao.deleteById com id correto', () async {
        // Arrange
        const refuelId = 'refuel-123';
        when(() => mockDao.deleteById(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.deleteRefuel(refuelId);

        // Assert
        expect(result, isRight());
        verify(() => mockDao.deleteById(refuelId)).called(1);
      });

      test('deve retornar Right(unit) quando deletar com sucesso', () async {
        // Arrange
        const refuelId = 'refuel-456';
        when(() => mockDao.deleteById(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.deleteRefuel(refuelId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        const refuelId = 'refuel-error';
        when(() => mockDao.deleteById(any())).thenThrow(Exception('Delete failed'));

        // Act
        final result = await repository.deleteRefuel(refuelId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao deletar reabastecimento');
      });
    });

    group('getRefuelById', () {
      test('deve retornar entity quando encontrado', () async {
        // Arrange
        const refuelId = 'refuel-789';
        final refuel = RefuelFactory.create();
        final row = _createRefuelRow(refuel);
        when(() => mockDao.getById(any())).thenAnswer((_) async => row);

        // Act
        final result = await repository.getRefuelById(refuelId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result)!.id, refuel.id);
        verify(() => mockDao.getById(refuelId)).called(1);
      });

      test('deve retornar Right(null) quando não encontrado', () async {
        // Arrange
        const refuelId = 'refuel-missing';
        when(() => mockDao.getById(any())).thenAnswer((_) async => null);

        // Act
        final result = await repository.getRefuelById(refuelId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), isNull);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        const refuelId = 'refuel-error';
        when(() => mockDao.getById(any())).thenThrow(Exception('Query failed'));

        // Act
        final result = await repository.getRefuelById(refuelId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao buscar reabastecimento');
      });
    });

    group('getAllByVehicleId', () {
      test('deve retornar lista de entities', () async {
        // Arrange
        const vehicleId = 'vehicle-123';
        final refuels = RefuelFactory.createList(3, vehicleId: vehicleId);
        final rows = refuels.map(_createRefuelRow).toList();
        when(() => mockDao.getAllByVehicleId(any())).thenAnswer((_) async => rows);

        // Act
        final result = await repository.getAllByVehicleId(vehicleId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result).length, 3);
        verify(() => mockDao.getAllByVehicleId(vehicleId)).called(1);
      });

      test('deve retornar Right([]) quando não houver abastecimentos', () async {
        // Arrange
        const vehicleId = 'vehicle-empty';
        when(() => mockDao.getAllByVehicleId(any())).thenAnswer((_) async => []);

        // Act
        final result = await repository.getAllByVehicleId(vehicleId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), isEmpty);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        const vehicleId = 'vehicle-error';
        when(() => mockDao.getAllByVehicleId(any())).thenThrow(Exception('Query failed'));

        // Act
        final result = await repository.getAllByVehicleId(vehicleId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao buscar reabastecimentos');
      });
    });

    group('watchAllByVehicleId', () {
      test('deve retornar Stream com Right(List<RefuelEntity>)', () async {
        // Arrange
        const vehicleId = 'vehicle-watch';
        final refuels = RefuelFactory.createList(2, vehicleId: vehicleId);
        final rows = refuels.map(_createRefuelRow).toList();
        when(() => mockDao.watchByVehicleId(any())).thenAnswer(
          (_) => Stream.value(rows),
        );

        // Act
        final stream = repository.watchAllByVehicleId(vehicleId);
        final result = await stream.first;

        // Assert
        expect(result, isRight());
        expect(rightValue(result).length, 2);
        verify(() => mockDao.watchByVehicleId(vehicleId)).called(1);
      });

      test('deve finalizar stream quando houver erro', () async {
        // Arrange
        const vehicleId = 'vehicle-stream-error';
        when(() => mockDao.watchByVehicleId(any())).thenAnswer(
          (_) => Stream.error(Exception('Stream failed')),
        );

        // Act
        final stream = repository.watchAllByVehicleId(vehicleId);

        // Assert
        await expectLater(
          stream,
          emitsDone,
        );
      });
    });

    group('getPreviousByVehicleId', () {
      test('deve retornar refuel anterior quando encontrado', () async {
        // Arrange
        const vehicleId = 'vehicle-999';
        final createdAt = DateTime(2026, 2, 1);
        const mileage = 50000;
        final refuel = RefuelFactory.createValid(vehicleId: vehicleId, mileage: 49000);
        final row = _createRefuelRow(refuel);
        when(
          () => mockDao.getPreviousByVehicleId(
            vehicleId,
            createdAt: createdAt,
            mileage: mileage,
          ),
        ).thenAnswer((_) async => row);

        // Act
        final result = await repository.getPreviousByVehicleId(
          vehicleId,
          createdAt: createdAt,
          mileage: mileage,
        );

        // Assert
        expect(result, isRight());
        expect(rightValue(result)!.vehicleId, vehicleId);
      });

      test('deve retornar Right(null) quando não houver anterior', () async {
        // Arrange
        const vehicleId = 'vehicle-none';
        final createdAt = DateTime(2026, 2, 10);
        const mileage = 60000;
        when(
          () => mockDao.getPreviousByVehicleId(
            vehicleId,
            createdAt: createdAt,
            mileage: mileage,
          ),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.getPreviousByVehicleId(
          vehicleId,
          createdAt: createdAt,
          mileage: mileage,
        );

        // Assert
        expect(result, isRight());
        expect(rightValue(result), isNull);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        const vehicleId = 'vehicle-error';
        final createdAt = DateTime(2026, 2, 15);
        const mileage = 70000;
        when(
          () => mockDao.getPreviousByVehicleId(
            vehicleId,
            createdAt: createdAt,
            mileage: mileage,
          ),
        ).thenThrow(Exception('Query failed'));

        // Act
        final result = await repository.getPreviousByVehicleId(
          vehicleId,
          createdAt: createdAt,
          mileage: mileage,
        );

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao buscar reabastecimento anterior');
      });
    });
  });
}

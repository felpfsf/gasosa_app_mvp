import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/data/local/dao/vehicle_dao.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/mappers/vehicle_mapper.dart';
import 'package:gasosa_app/data/repositories/vehicle_repository_impl.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:matcher/matcher.dart' as matcher;
import 'package:mocktail/mocktail.dart';

import '../../helpers/factories/vehicle_factory.dart';
import '../../helpers/test_helpers.dart';

class MockVehicleDao extends Mock implements VehicleDao {}

// Helper para criar VehicleRow a partir de VehicleEntity (simula dados do DAO)
VehicleRow _createVehicleRow(VehicleEntity entity) {
  return VehicleRow(
    id: entity.id,
    userId: entity.userId,
    name: entity.name,
    plate: entity.plate,
    tankCapacity: entity.tankCapacity,
    fuelType: entity.fuelType.name,
    photoPath: entity.photoPath,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}

void main() {
  late MockVehicleDao mockDao;
  late VehicleRepositoryImpl repository;

  setUp(() {
    mockDao = MockVehicleDao();
    repository = VehicleRepositoryImpl(mockDao);
  });

  setUpAll(() {
    registerFallbackValue(VehicleFactory.create());
    registerFallbackValue(VehicleMapper.toCompanion(VehicleFactory.create()));
  });

  group('VehicleRepositoryImpl -', () {
    group('createVehicle', () {
      test('deve chamar dao.upsert com companion correto', () async {
        // Arrange
        final vehicle = VehicleFactory.createNew();
        when(() => mockDao.upsert(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.createVehicle(vehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockDao.upsert(any(that: isA<VehiclesCompanion>()))).called(1);
      });

      test('deve retornar Right(unit) quando criar com sucesso', () async {
        // Arrange
        final vehicle = VehicleFactory.createNew();
        when(() => mockDao.upsert(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.createVehicle(vehicle);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        final vehicle = VehicleFactory.createNew();
        when(() => mockDao.upsert(any())).thenThrow(Exception('DB error'));

        // Act
        final result = await repository.createVehicle(vehicle);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao salvar veículo');
      });

      test('deve incluir causa do erro no DatabaseFailure', () async {
        // Arrange
        final vehicle = VehicleFactory.createNew();
        final exception = Exception('Unique constraint failed');
        when(() => mockDao.upsert(any())).thenThrow(exception);

        // Act
        final result = await repository.createVehicle(vehicle);

        // Assert
        final failure = leftFailure(result) as DatabaseFailure;
        expect(failure.cause, exception);
      });
    });

    group('updateVehicle', () {
      test('deve chamar dao.upsert com companion correto', () async {
        // Arrange
        final vehicle = VehicleFactory.create();
        when(() => mockDao.upsert(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.updateVehicle(vehicle);

        // Assert
        expect(result, isRight());
        verify(() => mockDao.upsert(any(that: isA<VehiclesCompanion>()))).called(1);
      });

      test('deve retornar Right(unit) quando atualizar com sucesso', () async {
        // Arrange
        final vehicle = VehicleFactory.create();
        when(() => mockDao.upsert(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.updateVehicle(vehicle);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        final vehicle = VehicleFactory.create();
        when(() => mockDao.upsert(any())).thenThrow(Exception('Update failed'));

        // Act
        final result = await repository.updateVehicle(vehicle);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao atualizar veículo');
      });
    });

    group('deleteVehicle', () {
      test('deve chamar dao.deleteById com id correto', () async {
        // Arrange
        const vehicleId = 'vehicle-123';
        when(() => mockDao.deleteById(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.deleteVehicle(vehicleId);

        // Assert
        expect(result, isRight());
        verify(() => mockDao.deleteById(vehicleId)).called(1);
      });

      test('deve retornar Right(unit) quando deletar com sucesso', () async {
        // Arrange
        const vehicleId = 'vehicle-456';
        when(() => mockDao.deleteById(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.deleteVehicle(vehicleId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), unit);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        const vehicleId = 'vehicle-error';
        when(() => mockDao.deleteById(any())).thenThrow(Exception('Delete failed'));

        // Act
        final result = await repository.deleteVehicle(vehicleId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao deletar veículo');
      });
    });

    group('getVehicleById', () {
      test('deve chamar dao.getById e retornar entity quando encontrado', () async {
        // Arrange
        const vehicleId = 'vehicle-789';
        final vehicle = VehicleFactory.create();
        final vehicleRow = _createVehicleRow(vehicle);
        when(() => mockDao.getById(any())).thenAnswer((_) async => vehicleRow);

        // Act
        final result = await repository.getVehicleById(vehicleId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), matcher.isNotNull);
        expect(rightValue(result)!.id, vehicle.id);
        verify(() => mockDao.getById(vehicleId)).called(1);
      });

      test('deve retornar Right(null) quando veículo não encontrado', () async {
        // Arrange
        const vehicleId = 'nonexistent';
        when(() => mockDao.getById(any())).thenAnswer((_) async => null);

        // Act
        final result = await repository.getVehicleById(vehicleId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), matcher.isNull);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        const vehicleId = 'error-id';
        when(() => mockDao.getById(any())).thenThrow(Exception('Query failed'));

        // Act
        final result = await repository.getVehicleById(vehicleId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao buscar veículo');
      });
    });

    group('getAllByUserId', () {
      test('deve chamar dao.getAllByUserId e retornar lista de entities', () async {
        // Arrange
        const userId = 'user-123';
        final vehicles = VehicleFactory.createList(3);
        final vehicleRows = vehicles.map(_createVehicleRow).toList();
        when(() => mockDao.getAllByUserId(any())).thenAnswer((_) async => vehicleRows);

        // Act
        final result = await repository.getAllByUserId(userId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result).length, 3);
        verify(() => mockDao.getAllByUserId(userId)).called(1);
      });

      test('deve retornar Right([]) quando usuário não tem veículos', () async {
        // Arrange
        const userId = 'user-empty';
        when(() => mockDao.getAllByUserId(any())).thenAnswer((_) async => []);

        // Act
        final result = await repository.getAllByUserId(userId);

        // Assert
        expect(result, isRight());
        expect(rightValue(result), isEmpty);
      });

      test('deve retornar Left(DatabaseFailure) quando dao lançar exceção', () async {
        // Arrange
        const userId = 'user-error';
        when(() => mockDao.getAllByUserId(any())).thenThrow(Exception('Query failed'));

        // Act
        final result = await repository.getAllByUserId(userId);

        // Assert
        expect(result, isLeft());
        expect(result, isLeftWith<DatabaseFailure>());
        expect(leftFailure(result).message, 'Erro ao listar veículos');
      });

      test('deve mapear corretamente todos os veículos', () async {
        // Arrange
        const userId = 'user-mapping';
        final vehicles = VehicleFactory.createList(5);
        final vehicleRows = vehicles.map(_createVehicleRow).toList();
        when(() => mockDao.getAllByUserId(any())).thenAnswer((_) async => vehicleRows);

        // Act
        final result = await repository.getAllByUserId(userId);

        // Assert
        final entities = rightValue(result);
        expect(entities.length, 5);
        for (var i = 0; i < vehicles.length; i++) {
          expect(entities[i].id, vehicles[i].id);
          expect(entities[i].name, vehicles[i].name);
        }
      });
    });

    group('watchAllByUserId', () {
      test('deve retornar Stream com Right(List<VehicleEntity>)', () async {
        // Arrange
        const userId = 'user-watch';
        final vehicles = VehicleFactory.createList(2);
        final vehicleRows = vehicles.map(_createVehicleRow).toList();
        when(() => mockDao.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(vehicleRows),
        );

        // Act
        final stream = repository.watchAllByUserId(userId);
        final result = await stream.first;

        // Assert
        expect(result, isRight());
        expect(rightValue(result).length, 2);
        verify(() => mockDao.watchAllByUserId(userId)).called(1);
      });

      test('deve emitir múltiplas atualizações quando dados mudam', () async {
        // Arrange
        const userId = 'user-updates';
        final vehicles1 = VehicleFactory.createList(1);
        final vehicles2 = VehicleFactory.createList(3);
        final table1 = vehicles1.map(_createVehicleRow).toList();
        final table2 = vehicles2.map(_createVehicleRow).toList();

        when(() => mockDao.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.fromIterable([table1, table2]),
        );

        // Act
        final stream = repository.watchAllByUserId(userId);
        final results = await stream.take(2).toList();

        // Assert
        expect(results.length, 2);
        expect(rightValue(results[0]).length, 1);
        expect(rightValue(results[1]).length, 3);
      });

      test('deve retornar Stream vazio quando usuário não tem veículos', () async {
        // Arrange
        const userId = 'user-no-vehicles';
        when(() => mockDao.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(<VehicleRow>[]),
        );

        // Act
        final stream = repository.watchAllByUserId(userId);
        final result = await stream.first;

        // Assert
        expect(result, isRight());
        expect(rightValue(result), isEmpty);
      });

      test('deve finalizar stream quando houver erro', () async {
        // Arrange
        const userId = 'user-stream-error';
        when(() => mockDao.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.error(Exception('Stream failed')),
        );

        // Act
        final stream = repository.watchAllByUserId(userId);

        // Assert
        await expectLater(
          stream,
          emitsDone,
        );
      });

      test('deve mapear corretamente TableData para Entity no stream', () async {
        // Arrange
        const userId = 'user-mapping-stream';
        final vehicles = VehicleFactory.createList(3);
        final vehicleRows = vehicles.map(_createVehicleRow).toList();
        when(() => mockDao.watchAllByUserId(any())).thenAnswer(
          (_) => Stream.value(vehicleRows),
        );

        // Act
        final stream = repository.watchAllByUserId(userId);
        final result = await stream.first;

        // Assert
        final entities = rightValue(result);
        for (var i = 0; i < vehicles.length; i++) {
          expect(entities[i].id, vehicles[i].id);
          expect(entities[i].name, vehicles[i].name);
          expect(entities[i].fuelType, vehicles[i].fuelType);
        }
      });
    });

    group('Mapeamento Entity ↔ TableData', () {
      test('deve preservar todos os campos ao mapear para companion e salvar', () async {
        // Arrange
        final vehicle = VehicleFactory.createFull();
        when(() => mockDao.upsert(any())).thenAnswer((_) async => 1);

        // Act
        await repository.createVehicle(vehicle);

        // Assert
        final companion = verify(() => mockDao.upsert(captureAny())).captured.first as VehiclesCompanion;
        expect(companion.id.value, vehicle.id);
        expect(companion.userId.value, vehicle.userId);
        expect(companion.name.value, vehicle.name);
        expect(companion.plate.value, vehicle.plate);
      });

      test('deve converter Entity para TableData e de volta corretamente', () async {
        // Arrange
        final originalVehicle = VehicleFactory.create();
        final vehicleRow = _createVehicleRow(originalVehicle);
        when(() => mockDao.getById(any())).thenAnswer((_) async => vehicleRow);

        // Act
        final result = await repository.getVehicleById(originalVehicle.id);

        // Assert
        final retrievedVehicle = rightValue(result)!;
        expect(retrievedVehicle.id, originalVehicle.id);
        expect(retrievedVehicle.name, originalVehicle.name);
        expect(retrievedVehicle.plate, originalVehicle.plate);
        expect(retrievedVehicle.tankCapacity, originalVehicle.tankCapacity);
        expect(retrievedVehicle.fuelType, originalVehicle.fuelType);
      });
    });
  });
}

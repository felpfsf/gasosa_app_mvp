import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/mappers/vehicle_mapper.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';

void main() {
  group('VehicleMapper', () {
    group('toDomain (VehicleRow -> VehicleEntity)', () {
      test('deve converter VehicleRow para VehicleEntity corretamente', () {
        // Arrange
        final row = VehicleRow(
          id: 'vehicle-123',
          userId: 'user-456',
          name: 'Honda Civic',
          plate: 'ABC1234',
          tankCapacity: 50.0,
          fuelType: 'gasoline',
          photoPath: '/path/to/photo.jpg',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.id, 'vehicle-123');
        expect(entity.userId, 'user-456');
        expect(entity.name, 'Honda Civic');
        expect(entity.plate, 'ABC1234');
        expect(entity.tankCapacity, 50.0);
        expect(entity.fuelType, FuelType.gasoline);
        expect(entity.photoPath, '/path/to/photo.jpg');
        expect(entity.createdAt, DateTime(2026, 1, 1));
        expect(entity.updatedAt, DateTime(2026, 1, 2));
      });

      test('deve converter VehicleRow com valores nulos opcionais', () {
        // Arrange
        final row = VehicleRow(
          id: 'vehicle-789',
          userId: 'user-456',
          name: 'Fiat Uno',
          plate: null,
          tankCapacity: null,
          fuelType: 'flex',
          photoPath: null,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: null,
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.id, 'vehicle-789');
        expect(entity.name, 'Fiat Uno');
        expect(entity.plate, isNull);
        expect(entity.tankCapacity, isNull);
        expect(entity.fuelType, FuelType.flex);
        expect(entity.photoPath, isNull);
        expect(entity.updatedAt, isNull);
      });

      test('deve mapear fuelType string "gasoline" para enum Gasoline', () {
        // Arrange
        final row = VehicleRow(
          id: 'v1',
          userId: 'u1',
          name: 'Test',
          fuelType: 'gasoline',
          createdAt: DateTime.now(),
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.fuelType, FuelType.gasoline);
      });

      test('deve mapear fuelType string "ethanol" para enum Ethanol', () {
        // Arrange
        final row = VehicleRow(
          id: 'v2',
          userId: 'u1',
          name: 'Test',
          fuelType: 'ethanol',
          createdAt: DateTime.now(),
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.fuelType, FuelType.ethanol);
      });

      test('deve mapear fuelType string "diesel" para enum Diesel', () {
        // Arrange
        final row = VehicleRow(
          id: 'v3',
          userId: 'u1',
          name: 'Test',
          fuelType: 'diesel',
          createdAt: DateTime.now(),
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.fuelType, FuelType.diesel);
      });

      test('deve mapear fuelType string "gnv" para enum GNV', () {
        // Arrange
        final row = VehicleRow(
          id: 'v4',
          userId: 'u1',
          name: 'Test',
          fuelType: 'gnv',
          createdAt: DateTime.now(),
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.fuelType, FuelType.gnv);
      });

      test('deve mapear fuelType string "flex" para enum Flex', () {
        // Arrange
        final row = VehicleRow(
          id: 'v5',
          userId: 'u1',
          name: 'Test',
          fuelType: 'flex',
          createdAt: DateTime.now(),
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.fuelType, FuelType.flex);
      });

      test('deve usar Flex como default quando fuelType é desconhecido', () {
        // Arrange
        final row = VehicleRow(
          id: 'v6',
          userId: 'u1',
          name: 'Test',
          fuelType: 'unknown',
          createdAt: DateTime.now(),
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.fuelType, FuelType.flex);
      });

      test('deve ser case-insensitive ao mapear fuelType', () {
        // Arrange
        final rows = [
          VehicleRow(id: 'v1', userId: 'u1', name: 'T', fuelType: 'GASOLINE', createdAt: DateTime.now()),
          VehicleRow(id: 'v2', userId: 'u1', name: 'T', fuelType: 'GaSOLinE', createdAt: DateTime.now()),
          VehicleRow(id: 'v3', userId: 'u1', name: 'T', fuelType: 'Ethanol', createdAt: DateTime.now()),
        ];

        for (final row in rows) {
          final entity = VehicleMapper.toDomain(row);
          expect(
            entity.fuelType,
            anyOf(FuelType.gasoline, FuelType.ethanol),
            reason: 'FuelType ${row.fuelType} deveria ser mapeado corretamente',
          );
        }
      });
    });

    group('toCompanion (VehicleEntity -> VehiclesCompanion)', () {
      test('deve converter VehicleEntity para VehiclesCompanion corretamente', () {
        // Arrange
        final entity = VehicleEntity(
          id: 'vehicle-123',
          userId: 'user-456',
          name: 'Honda Civic',
          plate: 'ABC1234',
          tankCapacity: 50.0,
          fuelType: FuelType.gasoline,
          photoPath: '/path/to/photo.jpg',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        );

        // Act
        final companion = VehicleMapper.toCompanion(entity);

        // Assert
        expect(companion.id.value, 'vehicle-123');
        expect(companion.userId.value, 'user-456');
        expect(companion.name.value, 'Honda Civic');
        expect(companion.plate.value, 'ABC1234');
        expect(companion.tankCapacity.value, 50.0);
        expect(companion.fuelType.value, 'gasoline');
        expect(companion.photoPath.value, '/path/to/photo.jpg');
        expect(companion.createdAt.value, DateTime(2026, 1, 1));
        expect(companion.updatedAt.value, DateTime(2026, 1, 2));
      });

      test('deve converter VehicleEntity com valores nulos opcionais', () {
        // Arrange
        final entity = VehicleEntity(
          id: 'vehicle-789',
          userId: 'user-456',
          name: 'Fiat Uno',
          fuelType: FuelType.flex,
          createdAt: DateTime(2026, 1, 1),
        );

        // Act
        final companion = VehicleMapper.toCompanion(entity);

        // Assert
        expect(companion.id.value, 'vehicle-789');
        expect(companion.name.value, 'Fiat Uno');
        expect(companion.plate.value, isNull);
        expect(companion.tankCapacity.value, isNull);
        expect(companion.fuelType.value, 'flex');
        expect(companion.photoPath.value, isNull);
        expect(companion.updatedAt.value, isNull);
      });

      test('deve converter enum FuelType para string corretamente', () {
        final testCases = [
          (FuelType.gasoline, 'gasoline'),
          (FuelType.ethanol, 'ethanol'),
          (FuelType.diesel, 'diesel'),
          (FuelType.gnv, 'gnv'),
          (FuelType.flex, 'flex'),
        ];

        for (final (fuelType, expectedString) in testCases) {
          final entity = VehicleEntity(
            id: 'test',
            userId: 'user',
            name: 'Test Vehicle',
            fuelType: fuelType,
            createdAt: DateTime.now(),
          );

          final companion = VehicleMapper.toCompanion(entity);

          expect(
            companion.fuelType.value,
            expectedString,
            reason: 'FuelType.$fuelType deveria ser convertido para "$expectedString"',
          );
        }
      });

      test('deve criar companion válido para insert', () {
        // Arrange
        final entity = VehicleEntity(
          id: '',
          userId: 'user-123',
          name: 'Novo Veículo',
          fuelType: FuelType.gasoline,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = VehicleMapper.toCompanion(entity);

        // Assert
        expect(companion.id.present, true);
        expect(companion.userId.present, true);
        expect(companion.name.present, true);
        expect(companion.fuelType.present, true);
        expect(companion.createdAt.present, true);
      });
    });

    group('Conversão bidirecional', () {
      test('deve manter dados após conversão VehicleRow -> Entity -> Companion', () {
        // Arrange
        final originalRow = VehicleRow(
          id: 'bidirectional-test',
          userId: 'user-999',
          name: 'Test Vehicle',
          plate: 'XYZ9876',
          tankCapacity: 60.0,
          fuelType: 'diesel',
          photoPath: '/test/path.jpg',
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 1, 20),
        );

        // Act
        final entity = VehicleMapper.toDomain(originalRow);
        final companion = VehicleMapper.toCompanion(entity);

        // Assert
        expect(companion.id.value, originalRow.id);
        expect(companion.userId.value, originalRow.userId);
        expect(companion.name.value, originalRow.name);
        expect(companion.plate.value, originalRow.plate);
        expect(companion.tankCapacity.value, originalRow.tankCapacity);
        expect(companion.fuelType.value, originalRow.fuelType);
        expect(companion.photoPath.value, originalRow.photoPath);
        expect(companion.createdAt.value, originalRow.createdAt);
        expect(companion.updatedAt.value, originalRow.updatedAt);
      });

      test('deve preservar FuelType em conversão round-trip', () {
        for (final fuelType in FuelType.values) {
          final entity = VehicleEntity(
            id: 'fuel-test',
            userId: 'user',
            name: 'Test',
            fuelType: fuelType,
            createdAt: DateTime.now(),
          );

          final companion = VehicleMapper.toCompanion(entity);
          final row = VehicleRow(
            id: companion.id.value,
            userId: companion.userId.value,
            name: companion.name.value,
            fuelType: companion.fuelType.value,
            createdAt: companion.createdAt.value,
          );
          final reconstructedEntity = VehicleMapper.toDomain(row);

          expect(
            reconstructedEntity.fuelType,
            fuelType,
            reason: 'FuelType.$fuelType deveria ser preservado em round-trip',
          );
        }
      });
    });

    group('Edge cases', () {
      test('deve lidar com nome vazio (mas não nulo)', () {
        // Arrange
        final entity = VehicleEntity(
          id: 'empty-name',
          userId: 'user-123',
          name: '',
          fuelType: FuelType.flex,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = VehicleMapper.toCompanion(entity);

        // Assert
        expect(companion.name.value, '');
      });

      test('deve lidar com capacidade de tanque 0.0', () {
        // Arrange
        final entity = VehicleEntity(
          id: 'zero-capacity',
          userId: 'user-123',
          name: 'Test',
          tankCapacity: 0.0,
          fuelType: FuelType.flex,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = VehicleMapper.toCompanion(entity);

        // Assert
        expect(companion.tankCapacity.value, 0.0);
      });

      test('deve lidar com caracteres especiais na placa', () {
        // Arrange
        final row = VehicleRow(
          id: 'special-plate',
          userId: 'user',
          name: 'Test',
          plate: 'ABC-1D23',
          fuelType: 'flex',
          createdAt: DateTime.now(),
        );

        // Act
        final entity = VehicleMapper.toDomain(row);

        // Assert
        expect(entity.plate, 'ABC-1D23');
      });

      test('deve lidar com path de foto muito longo', () {
        // Arrange
        final longPath = '/very/long/path/' + ('a' * 200) + '.jpg';
        final entity = VehicleEntity(
          id: 'long-path',
          userId: 'user',
          name: 'Test',
          photoPath: longPath,
          fuelType: FuelType.gasoline,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = VehicleMapper.toCompanion(entity);

        // Assert
        expect(companion.photoPath.value, longPath);
      });
    });
  });
}

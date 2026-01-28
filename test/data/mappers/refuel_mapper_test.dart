import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/mappers/refuel_mapper.dart';
import 'package:gasosa_app/domain/entities/fuel_type.dart';
import 'package:gasosa_app/domain/entities/refuel.dart';

void main() {
  group('RefuelMapper', () {
    group('toDomain (RefuelRow -> RefuelEntity)', () {
      test('deve converter RefuelRow para RefuelEntity corretamente', () {
        // Arrange
        final row = RefuelRow(
          id: 'refuel-123',
          vehicleId: 'vehicle-456',
          refuelDate: DateTime(2026, 1, 15),
          fuelType: 'gasoline',
          totalValue: 250.50,
          mileage: 50000,
          liters: 45.5,
          coldStartLiters: 2.0,
          coldStartValue: 12.50,
          receiptPath: '/receipts/photo.jpg',
          createdAt: DateTime(2026, 1, 15, 10, 30),
          updatedAt: DateTime(2026, 1, 15, 11, 00),
        );

        // Act
        final entity = RefuelMapper.toDomain(row);

        // Assert
        expect(entity.id, 'refuel-123');
        expect(entity.vehicleId, 'vehicle-456');
        expect(entity.refuelDate, DateTime(2026, 1, 15));
        expect(entity.fuelType, FuelType.gasoline);
        expect(entity.totalValue, 250.50);
        expect(entity.mileage, 50000);
        expect(entity.liters, 45.5);
        expect(entity.coldStartLiters, 2.0);
        expect(entity.coldStartValue, 12.50);
        expect(entity.receiptPath, '/receipts/photo.jpg');
        expect(entity.createdAt, DateTime(2026, 1, 15, 10, 30));
        expect(entity.updatedAt, DateTime(2026, 1, 15, 11, 00));
      });

      test('deve converter RefuelRow com valores opcionais nulos', () {
        // Arrange
        final row = RefuelRow(
          id: 'refuel-789',
          vehicleId: 'vehicle-456',
          refuelDate: DateTime(2026, 1, 20),
          fuelType: 'ethanol',
          totalValue: 180.00,
          mileage: 51000,
          liters: 40.0,
          coldStartLiters: null,
          coldStartValue: null,
          receiptPath: null,
          createdAt: DateTime(2026, 1, 20),
          updatedAt: null,
        );

        // Act
        final entity = RefuelMapper.toDomain(row);

        // Assert
        expect(entity.id, 'refuel-789');
        expect(entity.coldStartLiters, isNull);
        expect(entity.coldStartValue, isNull);
        expect(entity.receiptPath, isNull);
        expect(entity.updatedAt, isNull);
      });

      test('deve mapear todos os tipos de combustível corretamente', () {
        final testCases = [
          ('gasoline', FuelType.gasoline),
          ('ethanol', FuelType.ethanol),
          ('diesel', FuelType.diesel),
          ('gnv', FuelType.gnv),
          ('flex', FuelType.flex),
        ];

        for (final (fuelTypeString, expectedEnum) in testCases) {
          final row = RefuelRow(
            id: 'test',
            vehicleId: 'vehicle',
            refuelDate: DateTime.now(),
            fuelType: fuelTypeString,
            totalValue: 100.0,
            mileage: 50000,
            liters: 30.0,
            createdAt: DateTime.now(),
          );

          final entity = RefuelMapper.toDomain(row);

          expect(
            entity.fuelType,
            expectedEnum,
            reason: 'String "$fuelTypeString" deveria mapear para FuelType.$expectedEnum',
          );
        }
      });

      test('deve lidar com quilometragem 0 (veículo novo)', () {
        // Arrange
        final row = RefuelRow(
          id: 'first-refuel',
          vehicleId: 'new-vehicle',
          refuelDate: DateTime(2026, 1, 1),
          fuelType: 'flex',
          totalValue: 200.0,
          mileage: 0,
          liters: 50.0,
          createdAt: DateTime(2026, 1, 1),
        );

        // Act
        final entity = RefuelMapper.toDomain(row);

        // Assert
        expect(entity.mileage, 0);
      });

      test('deve lidar com valores decimais precisos', () {
        // Arrange
        final row = RefuelRow(
          id: 'precise-values',
          vehicleId: 'vehicle',
          refuelDate: DateTime.now(),
          fuelType: 'gasoline',
          totalValue: 123.456,
          mileage: 45678,
          liters: 22.789,
          coldStartLiters: 1.234,
          coldStartValue: 7.891,
          createdAt: DateTime.now(),
        );

        // Act
        final entity = RefuelMapper.toDomain(row);

        // Assert
        expect(entity.totalValue, 123.456);
        expect(entity.liters, 22.789);
        expect(entity.coldStartLiters, 1.234);
        expect(entity.coldStartValue, 7.891);
      });
    });

    group('toCompanion (RefuelEntity -> RefuelsCompanion)', () {
      test('deve converter RefuelEntity para RefuelsCompanion corretamente', () {
        // Arrange
        final entity = RefuelEntity(
          id: 'refuel-123',
          vehicleId: 'vehicle-456',
          refuelDate: DateTime(2026, 1, 15),
          fuelType: FuelType.gasoline,
          totalValue: 250.50,
          mileage: 50000,
          liters: 45.5,
          coldStartLiters: 2.0,
          coldStartValue: 12.50,
          receiptPath: '/receipts/photo.jpg',
          createdAt: DateTime(2026, 1, 15, 10, 30),
          updatedAt: DateTime(2026, 1, 15, 11, 00),
        );

        // Act
        final companion = RefuelMapper.toCompanion(entity);

        // Assert
        expect(companion.id.value, 'refuel-123');
        expect(companion.vehicleId.value, 'vehicle-456');
        expect(companion.refuelDate.value, DateTime(2026, 1, 15));
        expect(companion.fuelType.value, 'gasoline');
        expect(companion.totalValue.value, 250.50);
        expect(companion.mileage.value, 50000);
        expect(companion.liters.value, 45.5);
        expect(companion.coldStartLiters.value, 2.0);
        expect(companion.coldStartValue.value, 12.50);
        expect(companion.receiptPath.value, '/receipts/photo.jpg');
        expect(companion.createdAt.value, DateTime(2026, 1, 15, 10, 30));
        expect(companion.updatedAt.value, DateTime(2026, 1, 15, 11, 00));
      });

      test('deve converter RefuelEntity com valores opcionais nulos', () {
        // Arrange
        final entity = RefuelEntity(
          id: 'refuel-789',
          vehicleId: 'vehicle-456',
          refuelDate: DateTime(2026, 1, 20),
          fuelType: FuelType.ethanol,
          totalValue: 180.00,
          mileage: 51000,
          liters: 40.0,
          createdAt: DateTime(2026, 1, 20),
        );

        // Act
        final companion = RefuelMapper.toCompanion(entity);

        // Assert
        expect(companion.coldStartLiters.value, isNull);
        expect(companion.coldStartValue.value, isNull);
        expect(companion.receiptPath.value, isNull);
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

        for (final (fuelTypeEnum, expectedString) in testCases) {
          final entity = RefuelEntity(
            id: 'test',
            vehicleId: 'vehicle',
            refuelDate: DateTime.now(),
            fuelType: fuelTypeEnum,
            totalValue: 100.0,
            mileage: 50000,
            liters: 30.0,
            createdAt: DateTime.now(),
          );

          final companion = RefuelMapper.toCompanion(entity);

          expect(
            companion.fuelType.value,
            expectedString,
            reason: 'FuelType.$fuelTypeEnum deveria ser convertido para "$expectedString"',
          );
        }
      });

      test('deve criar companion válido para insert', () {
        // Arrange
        final entity = RefuelEntity(
          id: '',
          vehicleId: 'vehicle-123',
          refuelDate: DateTime.now(),
          fuelType: FuelType.gasoline,
          totalValue: 200.0,
          mileage: 45000,
          liters: 40.0,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = RefuelMapper.toCompanion(entity);

        // Assert
        expect(companion.id.present, true);
        expect(companion.vehicleId.present, true);
        expect(companion.refuelDate.present, true);
        expect(companion.fuelType.present, true);
        expect(companion.totalValue.present, true);
        expect(companion.mileage.present, true);
        expect(companion.liters.present, true);
        expect(companion.createdAt.present, true);
      });
    });

    group('Conversão bidirecional', () {
      test('deve manter dados após conversão RefuelRow -> Entity -> Companion', () {
        // Arrange
        final originalRow = RefuelRow(
          id: 'bidirectional-test',
          vehicleId: 'vehicle-999',
          refuelDate: DateTime(2026, 1, 25),
          fuelType: 'diesel',
          totalValue: 300.00,
          mileage: 60000,
          liters: 50.0,
          coldStartLiters: 3.0,
          coldStartValue: 18.00,
          receiptPath: '/test/receipt.jpg',
          createdAt: DateTime(2026, 1, 25, 8, 0),
          updatedAt: DateTime(2026, 1, 25, 9, 0),
        );

        // Act
        final entity = RefuelMapper.toDomain(originalRow);
        final companion = RefuelMapper.toCompanion(entity);

        // Assert
        expect(companion.id.value, originalRow.id);
        expect(companion.vehicleId.value, originalRow.vehicleId);
        expect(companion.refuelDate.value, originalRow.refuelDate);
        expect(companion.fuelType.value, originalRow.fuelType);
        expect(companion.totalValue.value, originalRow.totalValue);
        expect(companion.mileage.value, originalRow.mileage);
        expect(companion.liters.value, originalRow.liters);
        expect(companion.coldStartLiters.value, originalRow.coldStartLiters);
        expect(companion.coldStartValue.value, originalRow.coldStartValue);
        expect(companion.receiptPath.value, originalRow.receiptPath);
        expect(companion.createdAt.value, originalRow.createdAt);
        expect(companion.updatedAt.value, originalRow.updatedAt);
      });

      test('deve preservar FuelType em conversão round-trip', () {
        for (final fuelType in FuelType.values) {
          final entity = RefuelEntity(
            id: 'fuel-test',
            vehicleId: 'vehicle',
            refuelDate: DateTime.now(),
            fuelType: fuelType,
            totalValue: 150.0,
            mileage: 50000,
            liters: 35.0,
            createdAt: DateTime.now(),
          );

          final companion = RefuelMapper.toCompanion(entity);
          final row = RefuelRow(
            id: companion.id.value,
            vehicleId: companion.vehicleId.value,
            refuelDate: companion.refuelDate.value,
            fuelType: companion.fuelType.value,
            totalValue: companion.totalValue.value,
            mileage: companion.mileage.value,
            liters: companion.liters.value,
            createdAt: companion.createdAt.value,
          );
          final reconstructedEntity = RefuelMapper.toDomain(row);

          expect(
            reconstructedEntity.fuelType,
            fuelType,
            reason: 'FuelType.$fuelType deveria ser preservado em round-trip',
          );
        }
      });
    });

    group('Edge cases', () {
      test('deve lidar com quilometragem muito alta', () {
        // Arrange
        final entity = RefuelEntity(
          id: 'high-mileage',
          vehicleId: 'vehicle',
          refuelDate: DateTime.now(),
          fuelType: FuelType.diesel,
          totalValue: 400.0,
          mileage: 999999,
          liters: 80.0,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = RefuelMapper.toCompanion(entity);

        // Assert
        expect(companion.mileage.value, 999999);
      });

      test('deve lidar com valores muito pequenos', () {
        // Arrange
        final entity = RefuelEntity(
          id: 'small-values',
          vehicleId: 'vehicle',
          refuelDate: DateTime.now(),
          fuelType: FuelType.gasoline,
          totalValue: 0.01,
          mileage: 1,
          liters: 0.001,
          coldStartLiters: 0.001,
          coldStartValue: 0.01,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = RefuelMapper.toCompanion(entity);

        // Assert
        expect(companion.totalValue.value, 0.01);
        expect(companion.mileage.value, 1);
        expect(companion.liters.value, 0.001);
        expect(companion.coldStartLiters.value, 0.001);
        expect(companion.coldStartValue.value, 0.01);
      });

      test('deve lidar com path de recibo muito longo', () {
        // Arrange
        final longPath = '/receipts/' + ('a' * 200) + '.jpg';
        final entity = RefuelEntity(
          id: 'long-path',
          vehicleId: 'vehicle',
          refuelDate: DateTime.now(),
          fuelType: FuelType.flex,
          totalValue: 200.0,
          mileage: 50000,
          liters: 40.0,
          receiptPath: longPath,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = RefuelMapper.toCompanion(entity);

        // Assert
        expect(companion.receiptPath.value, longPath);
      });

      test('deve preservar precisão decimal em valores', () {
        // Arrange
        final entity = RefuelEntity(
          id: 'precise-decimals',
          vehicleId: 'vehicle',
          refuelDate: DateTime.now(),
          fuelType: FuelType.gasoline,
          totalValue: 199.999,
          mileage: 50000,
          liters: 36.367,
          coldStartLiters: 1.111,
          coldStartValue: 6.666,
          createdAt: DateTime.now(),
        );

        // Act
        final companion = RefuelMapper.toCompanion(entity);
        final row = RefuelRow(
          id: companion.id.value,
          vehicleId: companion.vehicleId.value,
          refuelDate: companion.refuelDate.value,
          fuelType: companion.fuelType.value,
          totalValue: companion.totalValue.value,
          mileage: companion.mileage.value,
          liters: companion.liters.value,
          coldStartLiters: companion.coldStartLiters.value,
          coldStartValue: companion.coldStartValue.value,
          createdAt: companion.createdAt.value,
        );
        final reconstructed = RefuelMapper.toDomain(row);

        // Assert
        expect(reconstructed.totalValue, 199.999);
        expect(reconstructed.liters, 36.367);
        expect(reconstructed.coldStartLiters, 1.111);
        expect(reconstructed.coldStartValue, 6.666);
      });

      test('deve lidar com datas no passado e futuro', () {
        final dates = [
          DateTime(2000, 1, 1),
          DateTime(2020, 12, 31),
          DateTime(2030, 6, 15),
        ];

        for (final date in dates) {
          final entity = RefuelEntity(
            id: 'date-test',
            vehicleId: 'vehicle',
            refuelDate: date,
            fuelType: FuelType.gasoline,
            totalValue: 100.0,
            mileage: 50000,
            liters: 30.0,
            createdAt: date,
          );

          final companion = RefuelMapper.toCompanion(entity);

          expect(companion.refuelDate.value, date);
          expect(companion.createdAt.value, date);
        }
      });
    });
  });
}

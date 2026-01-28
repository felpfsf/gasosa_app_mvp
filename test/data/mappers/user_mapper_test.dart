import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/data/local/db/app_database.dart';
import 'package:gasosa_app/data/mappers/user_mapper.dart';
import 'package:gasosa_app/domain/entities/user.dart';

void main() {
  group('UserMapper', () {
    group('fromData (UserRow -> UserEntity)', () {
      test('deve converter UserRow para UserEntity corretamente', () {
        // Arrange
        final row = UserRow(
          id: 'user-123',
          email: 'test@example.com',
          name: 'João Silva',
          photoUrl: 'https://example.com/photo.jpg',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

        // Act
        final entity = UserMapper.fromData(row);

        // Assert
        expect(entity.id, 'user-123');
        expect(entity.email, 'test@example.com');
        expect(entity.name, 'João Silva');
        expect(entity.photoUrl, 'https://example.com/photo.jpg');
      });

      test('deve converter UserRow com photoUrl nulo', () {
        // Arrange
        final row = UserRow(
          id: 'user-456',
          email: 'test2@example.com',
          name: 'Maria Santos',

          createdAt: DateTime(2026),
        );

        // Act
        final entity = UserMapper.fromData(row);

        // Assert
        expect(entity.id, 'user-456');
        expect(entity.email, 'test2@example.com');
        expect(entity.name, 'Maria Santos');
        expect(entity.photoUrl, isNull);
      });

      test('deve preservar todos os campos obrigatórios', () {
        // Arrange
        final row = UserRow(
          id: 'user-789',
          email: 'required@test.com',
          name: 'Teste User',
          createdAt: DateTime(2025, 12, 31),
          updatedAt: DateTime(2026),
        );

        // Act
        final entity = UserMapper.fromData(row);

        // Assert
        expect(entity.id, isNotEmpty);
        expect(entity.email, isNotEmpty);
        expect(entity.name, isNotEmpty);
      });
    });

    group('toCompanion (UserEntity -> UsersCompanion)', () {
      test('deve converter UserEntity para UsersCompanion corretamente', () {
        // Arrange
        const entity = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          name: 'João Silva',
          photoUrl: 'https://example.com/photo.jpg',
        );

        // Act
        final companion = UserMapper.toCompanion(entity);

        // Assert
        expect(companion.id.value, 'user-123');
        expect(companion.email.value, 'test@example.com');
        expect(companion.name.value, 'João Silva');
        expect(companion.photoUrl.value, 'https://example.com/photo.jpg');
      });

      test('deve converter UserEntity com photoUrl nulo', () {
        // Arrange
        const entity = UserEntity(
          id: 'user-456',
          email: 'test2@example.com',
          name: 'Maria Santos',
        );

        // Act
        final companion = UserMapper.toCompanion(entity);

        // Assert
        expect(companion.id.value, 'user-456');
        expect(companion.email.value, 'test2@example.com');
        expect(companion.name.value, 'Maria Santos');
        expect(companion.photoUrl.value, isNull);
      });

      test('deve criar companion válido para insert', () {
        // Arrange
        const entity = UserEntity(
          id: 'new-user',
          email: 'new@test.com',
          name: 'Novo Usuário',
        );

        // Act
        final companion = UserMapper.toCompanion(entity);

        // Assert
        expect(companion.id.present, true);
        expect(companion.email.present, true);
        expect(companion.name.present, true);
        expect(companion.photoUrl.present, true);
      });
    });

    group('toData (UserEntity -> UserRow)', () {
      test('deve converter UserEntity para UserRow corretamente', () {
        // Arrange
        const entity = UserEntity(
          id: 'user-123',
          email: 'test@example.com',
          name: 'João Silva',
          photoUrl: 'https://example.com/photo.jpg',
        );

        // Act
        final row = UserMapper.toData(entity);

        // Assert
        expect(row.id, 'user-123');
        expect(row.email, 'test@example.com');
        expect(row.name, 'João Silva');
        expect(row.photoUrl, 'https://example.com/photo.jpg');
        expect(row.createdAt, isA<DateTime>());
        expect(row.updatedAt, isA<DateTime>());
      });

      test('deve gerar timestamps automaticamente', () {
        // Arrange
        const entity = UserEntity(
          id: 'user-456',
          email: 'test@example.com',
          name: 'Test User',
        );

        final before = DateTime.now();

        // Act
        final row = UserMapper.toData(entity);

        final after = DateTime.now();

        // Assert
        expect(row.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(row.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
        expect(row.updatedAt?.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(row.updatedAt?.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('deve converter UserEntity com photoUrl nulo', () {
        // Arrange
        const entity = UserEntity(
          id: 'user-789',
          email: 'no-photo@test.com',
          name: 'Sem Foto',
        );

        // Act
        final row = UserMapper.toData(entity);

        // Assert
        expect(row.id, 'user-789');
        expect(row.photoUrl, isNull);
      });
    });

    group('Conversão bidirecional', () {
      test('deve manter dados após conversão UserRow -> Entity -> Row', () {
        // Arrange
        final originalRow = UserRow(
          id: 'bidirectional-test',
          email: 'bidirectional@test.com',
          name: 'Teste Bidirecional',
          photoUrl: 'https://test.com/photo.jpg',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026, 1, 2),
        );

        // Act
        final entity = UserMapper.fromData(originalRow);
        final newRow = UserMapper.toData(entity);

        // Assert
        expect(newRow.id, originalRow.id);
        expect(newRow.email, originalRow.email);
        expect(newRow.name, originalRow.name);
        expect(newRow.photoUrl, originalRow.photoUrl);
        // Nota: createdAt e updatedAt são regenerados em toData
      });

      test('deve manter dados após conversão Entity -> Companion -> Entity', () {
        // Arrange
        const originalEntity = UserEntity(
          id: 'round-trip',
          email: 'round@trip.com',
          name: 'Round Trip User',
          photoUrl: 'https://photo.url',
        );

        // Act
        final companion = UserMapper.toCompanion(originalEntity);

        // Assert
        expect(companion.id.value, originalEntity.id);
        expect(companion.email.value, originalEntity.email);
        expect(companion.name.value, originalEntity.name);
        expect(companion.photoUrl.value, originalEntity.photoUrl);
      });
    });

    group('Edge cases', () {
      test('deve lidar com strings vazias (mas não nulas)', () {
        // Arrange
        const entity = UserEntity(
          id: 'empty-string-test',
          email: '',
          name: '',
          photoUrl: '',
        );

        // Act
        final companion = UserMapper.toCompanion(entity);
        final row = UserMapper.toData(entity);

        // Assert
        expect(companion.email.value, '');
        expect(companion.name.value, '');
        expect(companion.photoUrl.value, '');
        expect(row.email, '');
        expect(row.name, '');
        expect(row.photoUrl, '');
      });

      test('deve lidar com caracteres especiais', () {
        // Arrange
        const entity = UserEntity(
          id: 'special-chars',
          email: 'test+tag@example.com',
          name: 'João "o Grande" Silva',
          photoUrl: 'https://example.com/path?query=value&other=123',
        );

        // Act
        final companion = UserMapper.toCompanion(entity);
        final row = UserMapper.toData(entity);

        // Assert
        expect(companion.email.value, 'test+tag@example.com');
        expect(companion.name.value, 'João "o Grande" Silva');
        expect(row.email, 'test+tag@example.com');
        expect(row.name, 'João "o Grande" Silva');
      });

      test('deve lidar com nomes muito longos', () {
        // Arrange
        final longName = 'A' * 100;
        final entity = UserEntity(
          id: 'long-name-test',
          email: 'long@test.com',
          name: longName,
        );

        // Act
        final row = UserMapper.toData(entity);

        // Assert
        expect(row.name, longName);
        expect(row.name.length, 100);
      });
    });
  });
}

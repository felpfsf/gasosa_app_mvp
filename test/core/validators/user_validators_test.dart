import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/core/validators/user_validators.dart';

void main() {
  group('UserValidators.name', () {
    test('deve retornar null quando nome válido', () {
      // Arrange
      const validName = 'João Silva';

      // Act
      final result = UserValidators.name(validName);

      // Assert
      expect(result, isNull);
    });

    test('deve retornar erro quando nome vazio', () {
      // Arrange
      const emptyName = '';

      // Act
      final result = UserValidators.name(emptyName);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('obrigatório'));
    });

    test('deve retornar erro quando nome nulo', () {
      // Act
      final result = UserValidators.name(null);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('obrigatório'));
    });

    test('deve retornar erro quando nome tem menos de 2 caracteres', () {
      // Arrange
      const shortName = 'A';

      // Act
      final result = UserValidators.name(shortName);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('pelo menos 2 caracteres'));
    });

    test('deve retornar erro quando nome tem mais de 50 caracteres', () {
      // Arrange
      final longName = 'A' * 51;

      // Act
      final result = UserValidators.name(longName);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('no máximo 50 caracteres'));
    });

    test('deve aceitar nome com 2 caracteres (mínimo válido)', () {
      // Arrange
      const minName = 'Ab';

      // Act
      final result = UserValidators.name(minName);

      // Assert
      expect(result, isNull);
    });

    test('deve aceitar nome com 50 caracteres (máximo válido)', () {
      // Arrange
      final maxName = 'A' * 50;

      // Act
      final result = UserValidators.name(maxName);

      // Assert
      expect(result, isNull);
    });

    test('deve aceitar nome com espaços', () {
      // Arrange
      const nameWithSpaces = 'Maria da Silva';

      // Act
      final result = UserValidators.name(nameWithSpaces);

      // Assert
      expect(result, isNull);
    });

    test('deve aceitar nome com caracteres acentuados', () {
      // Arrange
      const nameWithAccents = 'José Antônio';

      // Act
      final result = UserValidators.name(nameWithAccents);

      // Assert
      expect(result, isNull);
    });
  });

  group('UserValidators.email', () {
    test('deve retornar null quando email válido', () {
      // Arrange
      const validEmail = 'test@example.com';

      // Act
      final result = UserValidators.email(validEmail);

      // Assert
      expect(result, isNull);
    });

    test('deve retornar erro quando email vazio', () {
      // Arrange
      const emptyEmail = '';

      // Act
      final result = UserValidators.email(emptyEmail);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('obrigatório'));
    });

    test('deve retornar erro quando email nulo', () {
      // Act
      final result = UserValidators.email(null);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('obrigatório'));
    });

    test('deve retornar erro quando email sem @', () {
      // Arrange
      const invalidEmail = 'testexample.com';

      // Act
      final result = UserValidators.email(invalidEmail);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('inválido'));
    });

    test('deve retornar erro quando email sem domínio', () {
      // Arrange
      const invalidEmail = 'test@';

      // Act
      final result = UserValidators.email(invalidEmail);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('inválido'));
    });

    test('deve retornar erro quando email sem parte local', () {
      // Arrange
      const invalidEmail = '@example.com';

      // Act
      final result = UserValidators.email(invalidEmail);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('inválido'));
    });

    test('deve aceitar email com subdomínio', () {
      // Arrange
      const emailWithSubdomain = 'user@mail.example.com';

      // Act
      final result = UserValidators.email(emailWithSubdomain);

      // Assert
      expect(result, isNull);
    });

    test('deve aceitar email com números', () {
      // Arrange
      const emailWithNumbers = 'user123@example.com';

      // Act
      final result = UserValidators.email(emailWithNumbers);

      // Assert
      expect(result, isNull);
    });

    test('deve aceitar email com underline e ponto', () {
      // Arrange
      const complexEmail = 'user.name_123@example.com';

      // Act
      final result = UserValidators.email(complexEmail);

      // Assert
      expect(result, isNull);
    });
  });

  group('UserValidators.password', () {
    test('deve retornar null quando senha válida', () {
      // Arrange
      const validPassword = '123456';

      // Act
      final result = UserValidators.password(validPassword);

      // Assert
      expect(result, isNull);
    });

    test('deve retornar erro quando senha vazia', () {
      // Arrange
      const emptyPassword = '';

      // Act
      final result = UserValidators.password(emptyPassword);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('obrigatória'));
    });

    test('deve retornar erro quando senha nula', () {
      // Act
      final result = UserValidators.password(null);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('obrigatória'));
    });

    test('deve retornar erro quando senha tem menos de 6 caracteres', () {
      // Arrange
      const shortPassword = '12345';

      // Act
      final result = UserValidators.password(shortPassword);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('pelo menos 6 caracteres'));
    });

    test('deve aceitar senha com exatamente 6 caracteres', () {
      // Arrange
      const minPassword = '123456';

      // Act
      final result = UserValidators.password(minPassword);

      // Assert
      expect(result, isNull);
    });

    test('deve aceitar senha longa', () {
      // Arrange
      const longPassword = 'ThisIsAVeryLongPassword123!@#';

      // Act
      final result = UserValidators.password(longPassword);

      // Assert
      expect(result, isNull);
    });

    test('deve aceitar senha com caracteres especiais', () {
      // Arrange
      const passwordWithSpecialChars = 'Pass@123!';

      // Act
      final result = UserValidators.password(passwordWithSpecialChars);

      // Assert
      expect(result, isNull);
    });
  });

  group('UserValidators.confirmPassword', () {
    late TextEditingController passwordController;

    setUp(() {
      passwordController = TextEditingController();
    });

    tearDown(() {
      passwordController.dispose();
    });

    test('deve retornar null quando senhas coincidem', () {
      // Arrange
      const password = '123456';
      passwordController.text = password;
      final validator = UserValidators.confirmPassword(passwordController);

      // Act
      final result = validator(password);

      // Assert
      expect(result, isNull);
    });

    test('deve retornar erro quando confirmação está vazia', () {
      // Arrange
      passwordController.text = '123456';
      final validator = UserValidators.confirmPassword(passwordController);

      // Act
      final result = validator('');

      // Assert
      expect(result, isNotNull);
      expect(result, contains('obrigatória'));
    });

    test('deve retornar erro quando confirmação é nula', () {
      // Arrange
      passwordController.text = '123456';
      final validator = UserValidators.confirmPassword(passwordController);

      // Act
      final result = validator(null);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('obrigatória'));
    });

    test('deve retornar erro quando confirmação tem menos de 6 caracteres', () {
      // Arrange
      passwordController.text = '123456';
      final validator = UserValidators.confirmPassword(passwordController);

      // Act
      final result = validator('12345');

      // Assert
      expect(result, isNotNull);
      expect(result, contains('pelo menos 6 caracteres'));
    });

    test('deve retornar erro quando senhas não coincidem', () {
      // Arrange
      passwordController.text = '123456';
      final validator = UserValidators.confirmPassword(passwordController);

      // Act
      final result = validator('654321');

      // Assert
      expect(result, isNotNull);
      expect(result, contains('não coincidem'));
    });

    test('deve retornar erro quando confirmação é diferente com mesmo tamanho', () {
      // Arrange
      passwordController.text = 'password123';
      final validator = UserValidators.confirmPassword(passwordController);

      // Act
      final result = validator('password456');

      // Assert
      expect(result, isNotNull);
      expect(result, contains('não coincidem'));
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/auth/register_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late RegisterCommand command;

  setUp(() {
    mockAuthService = MockAuthService();
    command = RegisterCommand(auth: mockAuthService);
  });

  group('RegisterCommand', () {
    const testName = 'João Silva';
    const testEmail = 'joao@example.com';
    const testPassword = 'password123';
    const testUser = AuthUser('new-user-123', testName, testEmail);

    group('Sucesso', () {
      test('deve retornar Right com AuthUser quando registro bem-sucedido', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, testEmail, testPassword),
        ).thenAnswer((_) async => right(testUser));

        // Act
        final result = await command(name: testName, email: testEmail, password: testPassword);

        // Assert
        expect(result, isA<Right<Failure, AuthUser>>());
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) {
            expect(user.id, 'new-user-123');
            expect(user.name, testName);
            expect(user.email, testEmail);
          },
        );
        verify(() => mockAuthService.register(testName, testEmail, testPassword)).called(1);
      });

      test('deve criar usuário com nome composto', () async {
        // Arrange
        const compoundName = 'Maria José dos Santos Silva';
        const userWithCompoundName = AuthUser('user-456', compoundName, testEmail);
        when(
          () => mockAuthService.register(compoundName, testEmail, testPassword),
        ).thenAnswer((_) async => right(userWithCompoundName));

        // Act
        final result = await command(name: compoundName, email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) => expect(user.name, compoundName),
        );
      });

      test('deve criar usuário com senha forte', () async {
        // Arrange
        const strongPassword = 'S3nh@F0rt3!#\$';
        when(
          () => mockAuthService.register(testName, testEmail, strongPassword),
        ).thenAnswer((_) async => right(testUser));

        // Act
        final result = await command(name: testName, email: testEmail, password: strongPassword);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockAuthService.register(testName, testEmail, strongPassword)).called(1);
      });

      test('deve aceitar email com subdomínio', () async {
        // Arrange
        const complexEmail = 'user@subdomain.example.com';
        const userWithComplexEmail = AuthUser('user-789', testName, complexEmail);
        when(
          () => mockAuthService.register(testName, complexEmail, testPassword),
        ).thenAnswer((_) async => right(userWithComplexEmail));

        // Act
        final result = await command(name: testName, email: complexEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) => expect(user.email, complexEmail),
        );
      });
    });

    group('Falhas de Validação', () {
      test('deve retornar Left com BusinessFailure quando nome vazio', () async {
        // Arrange
        when(
          () => mockAuthService.register('', testEmail, testPassword),
        ).thenAnswer((_) async => left(const BusinessFailure('Nome não pode ser vazio')));

        // Act
        final result = await command(name: '', email: testEmail, password: testPassword);

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<BusinessFailure>());
            expect(failure.message, 'Nome não pode ser vazio');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com BusinessFailure quando email vazio', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, '', testPassword),
        ).thenAnswer((_) async => left(const BusinessFailure('Email não pode ser vazio')));

        // Act
        final result = await command(name: testName, email: '', password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<BusinessFailure>());
            expect(failure.message, 'Email não pode ser vazio');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com BusinessFailure quando password vazio', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, testEmail, ''),
        ).thenAnswer((_) async => left(const BusinessFailure('Senha não pode ser vazia')));

        // Act
        final result = await command(name: testName, email: testEmail, password: '');

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<BusinessFailure>());
            expect(failure.message, 'Senha não pode ser vazia');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com BusinessFailure quando email inválido', () async {
        // Arrange
        const invalidEmail = 'invalid-email-format';
        when(
          () => mockAuthService.register(testName, invalidEmail, testPassword),
        ).thenAnswer((_) async => left(const BusinessFailure('Email inválido')));

        // Act
        final result = await command(name: testName, email: invalidEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<BusinessFailure>());
            expect(failure.message, 'Email inválido');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com BusinessFailure quando senha fraca', () async {
        // Arrange
        const weakPassword = '123';
        when(
          () => mockAuthService.register(testName, testEmail, weakPassword),
        ).thenAnswer((_) async => left(const BusinessFailure('Senha muito fraca')));

        // Act
        final result = await command(name: testName, email: testEmail, password: weakPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<BusinessFailure>());
            expect(failure.message, 'Senha muito fraca');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com BusinessFailure quando senha menor que 6 caracteres', () async {
        // Arrange
        const shortPassword = '12345';
        when(
          () => mockAuthService.register(testName, testEmail, shortPassword),
        ).thenAnswer((_) async => left(const BusinessFailure('Senha deve ter no mínimo 6 caracteres')));

        // Act
        final result = await command(name: testName, email: testEmail, password: shortPassword);

        // Assert
        result.fold(
          (failure) => expect(failure.message, contains('mínimo 6 caracteres')),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com BusinessFailure quando nome muito curto', () async {
        // Arrange
        const shortName = 'A';
        when(
          () => mockAuthService.register(shortName, testEmail, testPassword),
        ).thenAnswer((_) async => left(const BusinessFailure('Nome muito curto')));

        // Act
        final result = await command(name: shortName, email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => expect(failure.message, 'Nome muito curto'),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Falhas de Autenticação', () {
      test('deve retornar Left com AuthFailure quando email já cadastrado', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, testEmail, testPassword),
        ).thenAnswer((_) async => left(const AuthFailure('Email já cadastrado')));

        // Act
        final result = await command(name: testName, email: testEmail, password: testPassword);

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Email já cadastrado');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com AuthFailure quando domínio email bloqueado', () async {
        // Arrange
        const blockedEmail = 'user@blocked-domain.com';
        when(
          () => mockAuthService.register(testName, blockedEmail, testPassword),
        ).thenAnswer((_) async => left(const AuthFailure('Domínio de email não autorizado')));

        // Act
        final result = await command(name: testName, email: blockedEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => expect(failure.message, 'Domínio de email não autorizado'),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com AuthFailure quando muitas tentativas de registro', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, testEmail, testPassword),
        ).thenAnswer((_) async => left(const AuthFailure('Muitas tentativas, tente novamente mais tarde')));

        // Act
        final result = await command(name: testName, email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => expect(failure.message, contains('Muitas tentativas')),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Falhas de Sistema', () {
      test('deve retornar Left com AuthFailure quando sem conexão', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, testEmail, testPassword),
        ).thenAnswer((_) async => left(const AuthFailure('Sem conexão com a internet')));

        // Act
        final result = await command(name: testName, email: testEmail, password: testPassword);

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Sem conexão com a internet');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com AuthFailure quando timeout', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, testEmail, testPassword),
        ).thenAnswer((_) async => left(const AuthFailure('Timeout na requisição')));

        // Act
        final result = await command(name: testName, email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Timeout na requisição');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com AuthFailure quando erro inesperado', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, testEmail, testPassword),
        ).thenAnswer((_) async => left(const AuthFailure('Erro inesperado no registro')));

        // Act
        final result = await command(name: testName, email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Erro inesperado no registro');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Edge Cases', () {
      test('deve lidar com caracteres especiais no nome', () async {
        // Arrange
        const nameWithSpecialChars = "José da O'Neil-Smith";
        const userWithSpecialName = AuthUser('user-special', nameWithSpecialChars, testEmail);
        when(
          () => mockAuthService.register(nameWithSpecialChars, testEmail, testPassword),
        ).thenAnswer((_) async => right(userWithSpecialName));

        // Act
        final result = await command(name: nameWithSpecialChars, email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) => expect(user.name, nameWithSpecialChars),
        );
      });

      test('deve lidar com email com caracteres especiais válidos', () async {
        // Arrange
        const specialEmail = 'user+tag@example.com';
        const userWithSpecialEmail = AuthUser('user-tag', testName, specialEmail);
        when(
          () => mockAuthService.register(testName, specialEmail, testPassword),
        ).thenAnswer((_) async => right(userWithSpecialEmail));

        // Act
        final result = await command(name: testName, email: specialEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) => expect(user.email, specialEmail),
        );
      });

      test('deve lidar com espaços em branco nos campos', () async {
        // Arrange
        when(
          () => mockAuthService.register('  $testName  ', '  $testEmail  ', '  $testPassword  '),
        ).thenAnswer((_) async => left(const BusinessFailure('Campos com espaços em branco')));

        // Act
        final result = await command(
          name: '  $testName  ',
          email: '  $testEmail  ',
          password: '  $testPassword  ',
        );

        // Assert
        result.fold(
          (failure) => expect(failure, isA<BusinessFailure>()),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve chamar AuthService apenas uma vez', () async {
        // Arrange
        when(
          () => mockAuthService.register(testName, testEmail, testPassword),
        ).thenAnswer((_) async => right(testUser));

        // Act
        await command(name: testName, email: testEmail, password: testPassword);

        // Assert
        verify(() => mockAuthService.register(testName, testEmail, testPassword)).called(1);
        verifyNoMoreInteractions(mockAuthService);
      });

      test('deve permitir múltiplos registros sequenciais', () async {
        // Arrange
        const user1 = AuthUser('user-1', 'User One', 'user1@test.com');
        const user2 = AuthUser('user-2', 'User Two', 'user2@test.com');

        when(
          () => mockAuthService.register('User One', 'user1@test.com', 'pass1'),
        ).thenAnswer((_) async => right(user1));
        when(
          () => mockAuthService.register('User Two', 'user2@test.com', 'pass2'),
        ).thenAnswer((_) async => right(user2));

        // Act
        final result1 = await command(name: 'User One', email: 'user1@test.com', password: 'pass1');
        final result2 = await command(name: 'User Two', email: 'user2@test.com', password: 'pass2');

        // Assert
        expect(result1.isRight(), true);
        expect(result2.isRight(), true);
      });
    });
  });
}

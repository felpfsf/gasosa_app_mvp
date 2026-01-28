import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/commands/auth/login_email_password_command.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late LoginEmailPasswordCommand command;

  setUp(() {
    mockAuthService = MockAuthService();
    command = LoginEmailPasswordCommand(auth: mockAuthService);
  });

  group('LoginEmailPasswordCommand', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUser = AuthUser('user-123', 'Test User', testEmail);

    group('Sucesso', () {
      test('deve retornar Right com AuthUser quando login bem-sucedido', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => right(testUser));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        expect(result, isA<Right<Failure, AuthUser>>());
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) {
            expect(user.id, 'user-123');
            expect(user.name, 'Test User');
            expect(user.email, testEmail);
          },
        );
        verify(() => mockAuthService.loginWithEmail(testEmail, testPassword)).called(1);
      });

      test('deve incluir photoUrl quando presente', () async {
        // Arrange
        const userWithPhoto = AuthUser('user-123', 'Test User', testEmail, photoUrl: 'https://example.com/photo.jpg');
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => right(userWithPhoto));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) => expect(user.photoUrl, 'https://example.com/photo.jpg'),
        );
      });
    });

    group('Falhas de Validação', () {
      test('deve retornar Left com BusinessFailure quando email vazio', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail('', testPassword))
            .thenAnswer((_) async => left(const BusinessFailure('Email não pode ser vazio')));

        // Act
        final result = await command(email: '', password: testPassword);

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<BusinessFailure>());
            expect(failure.message, 'Email não pode ser vazio');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
        verify(() => mockAuthService.loginWithEmail('', testPassword)).called(1);
      });

      test('deve retornar Left com BusinessFailure quando password vazio', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, ''))
            .thenAnswer((_) async => left(const BusinessFailure('Senha não pode ser vazia')));

        // Act
        final result = await command(email: testEmail, password: '');

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
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
        const invalidEmail = 'invalid-email';
        when(() => mockAuthService.loginWithEmail(invalidEmail, testPassword))
            .thenAnswer((_) async => left(const BusinessFailure('Email inválido')));

        // Act
        final result = await command(email: invalidEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<BusinessFailure>());
            expect(failure.message, 'Email inválido');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Falhas de Autenticação', () {
      test('deve retornar Left com AuthFailure quando credenciais inválidas', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, 'wrong-password'))
            .thenAnswer((_) async => left(AuthFailure('Credenciais inválidas')));

        // Act
        final result = await command(email: testEmail, password: 'wrong-password');

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Credenciais inválidas');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com AuthFailure quando usuário não existe', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail('nonexistent@test.com', testPassword))
            .thenAnswer((_) async => left(AuthFailure('Usuário não encontrado')));

        // Act
        final result = await command(email: 'nonexistent@test.com', password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Usuário não encontrado');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com AuthFailure quando email não verificado', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => left(AuthFailure('Email não verificado')));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Email não verificado');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com AuthFailure quando conta desabilitada', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => left(AuthFailure('Conta desabilitada')));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) => expect(failure.message, 'Conta desabilitada'),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Falhas de Sistema', () {
      test('deve retornar Left com AuthFailure quando sem conexão', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => left(const AuthFailure('Sem conexão com a internet')));

        // Act
        final result = await command(email: testEmail, password: testPassword);

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

      test('deve retornar Left com AuthFailure quando erro inesperado', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => left(const AuthFailure('Erro inesperado')));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Erro inesperado');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com AuthFailure quando timeout', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => left(const AuthFailure('Timeout na requisição')));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.message, 'Timeout na requisição');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Edge Cases', () {
      test('deve lidar com email e password com espaços em branco', () async {
        // Arrange
        const emailWithSpaces = '  test@example.com  ';
        const passwordWithSpaces = '  password123  ';
        when(() => mockAuthService.loginWithEmail(emailWithSpaces, passwordWithSpaces))
            .thenAnswer((_) async => left(const BusinessFailure('Email/senha com espaços')));

        // Act
        final result = await command(email: emailWithSpaces, password: passwordWithSpaces);

        // Assert
        result.fold(
          (failure) => expect(failure, isA<BusinessFailure>()),
          (user) => fail('Não deveria retornar sucesso'),
        );
        verify(() => mockAuthService.loginWithEmail(emailWithSpaces, passwordWithSpaces)).called(1);
      });

      test('deve lidar com caracteres especiais no password', () async {
        // Arrange
        const specialPassword = 'P@ssw0rd!@#\$%^&*()';
        when(() => mockAuthService.loginWithEmail(testEmail, specialPassword))
            .thenAnswer((_) async => right(testUser));

        // Act
        final result = await command(email: testEmail, password: specialPassword);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockAuthService.loginWithEmail(testEmail, specialPassword)).called(1);
      });

      test('deve lidar com email em maiúsculas', () async {
        // Arrange
        const uppercaseEmail = 'TEST@EXAMPLE.COM';
        when(() => mockAuthService.loginWithEmail(uppercaseEmail, testPassword))
            .thenAnswer((_) async => right(testUser));

        // Act
        final result = await command(email: uppercaseEmail, password: testPassword);

        // Assert
        expect(result.isRight(), true);
      });

      test('deve chamar AuthService apenas uma vez por comando', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => right(testUser));

        // Act
        await command(email: testEmail, password: testPassword);

        // Assert
        verify(() => mockAuthService.loginWithEmail(testEmail, testPassword)).called(1);
        verifyNoMoreInteractions(mockAuthService);
      });
    });
  });
}

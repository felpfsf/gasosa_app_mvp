import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/auth/login_email_password_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/repositories/user_repository.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockObservabilityService extends Mock implements ObservabilityService {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockAuthService mockAuthService;
  late MockObservabilityService mockObservability;
  late MockUserRepository mockUserRepository;
  late LoginEmailPasswordUseCase command;

  setUpAll(() {
    registerFallbackValue(const UnexpectedFailure('', null, null));
    registerFallbackValue(const AuthUser('', '', ''));
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockObservability = MockObservabilityService();
    mockUserRepository = MockUserRepository();
    command = LoginEmailPasswordUseCase(
      auth: mockAuthService,
      observability: mockObservability,
      userRepository: mockUserRepository,
    );

    when(() => mockUserRepository.saveUser(any())).thenAnswer((_) async => right(unit));

    when(() => mockObservability.logBreadcrumb(any(), data: any(named: 'data'))).thenReturn(null);
    when(() => mockObservability.logEvent(any(), parameters: any(named: 'parameters'))).thenAnswer((_) async {});
    when(
      () => mockObservability.logError(
        any(),
        stackTrace: any(named: 'stackTrace'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockObservability.setUserId(any())).thenReturn(null);
  });

  group('LoginEmailPasswordUseCase', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUser = AuthUser('user-123', 'Test User', testEmail);

    group('Sucesso', () {
      test('deve retornar Right com AuthUser quando login bem-sucedido', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword)).thenAnswer((_) async => right(testUser));

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
        when(
          () => mockAuthService.loginWithEmail(testEmail, testPassword),
        ).thenAnswer((_) async => right(userWithPhoto));

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
      test('deve retornar Left com ValidationFailure quando email vazio', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail('', testPassword),
        ).thenAnswer((_) async => left(const ValidationFailure('Email não pode ser vazio')));

        // Act
        final result = await command(email: '', password: testPassword);

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Email não pode ser vazio');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
        verify(() => mockAuthService.loginWithEmail('', testPassword)).called(1);
      });

      test('deve retornar Left com ValidationFailure quando password vazio', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail(testEmail, ''),
        ).thenAnswer((_) async => left(const ValidationFailure('Senha não pode ser vazia')));

        // Act
        final result = await command(email: testEmail, password: '');

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Senha não pode ser vazia');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com ValidationFailure quando email inválido', () async {
        // Arrange
        const invalidEmail = 'invalid-email';
        when(
          () => mockAuthService.loginWithEmail(invalidEmail, testPassword),
        ).thenAnswer((_) async => left(const ValidationFailure('Email inválido')));

        // Act
        final result = await command(email: invalidEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Email inválido');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Falhas de Autenticação', () {
      test('deve retornar Left com UnexpectedFailure quando credenciais inválidas', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail(testEmail, 'wrong-password'),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Credenciais inválidas', null, null)));

        // Act
        final result = await command(email: testEmail, password: 'wrong-password');

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Credenciais inválidas');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando usuário não existe', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail('nonexistent@test.com', testPassword),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Usuário não encontrado', null, null)));

        // Act
        final result = await command(email: 'nonexistent@test.com', password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Usuário não encontrado');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando email não verificado', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail(testEmail, testPassword),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Email não verificado', null, null)));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Email não verificado');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando conta desabilitada', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail(testEmail, testPassword),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Conta desabilitada', null, null)));

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
      test('deve retornar Left com UnexpectedFailure quando sem conexão', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail(testEmail, testPassword),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Sem conexão com a internet', null, null)));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Sem conexão com a internet');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando erro inesperado', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail(testEmail, testPassword),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Erro inesperado', null, null)));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Erro inesperado');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando timeout', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithEmail(testEmail, testPassword),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Timeout na requisição', null, null)));

        // Act
        final result = await command(email: testEmail, password: testPassword);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
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
        when(
          () => mockAuthService.loginWithEmail(emailWithSpaces, passwordWithSpaces),
        ).thenAnswer((_) async => left(const ValidationFailure('Email/senha com espaços')));

        // Act
        final result = await command(email: emailWithSpaces, password: passwordWithSpaces);

        // Assert
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (user) => fail('Não deveria retornar sucesso'),
        );
        verify(() => mockAuthService.loginWithEmail(emailWithSpaces, passwordWithSpaces)).called(1);
      });

      test('deve lidar com caracteres especiais no password', () async {
        // Arrange
        const specialPassword = 'P@ssw0rd!@#\$%^&*()';
        when(() => mockAuthService.loginWithEmail(testEmail, specialPassword)).thenAnswer((_) async => right(testUser));

        // Act
        final result = await command(email: testEmail, password: specialPassword);

        // Assert
        expect(result.isRight, true);
        verify(() => mockAuthService.loginWithEmail(testEmail, specialPassword)).called(1);
      });

      test('deve lidar com email em maiúsculas', () async {
        // Arrange
        const uppercaseEmail = 'TEST@EXAMPLE.COM';
        when(
          () => mockAuthService.loginWithEmail(uppercaseEmail, testPassword),
        ).thenAnswer((_) async => right(testUser));

        // Act
        final result = await command(email: uppercaseEmail, password: testPassword);

        // Assert
        expect(result.isRight, true);
      });

      test('deve chamar AuthService apenas uma vez por comando', () async {
        // Arrange
        when(() => mockAuthService.loginWithEmail(testEmail, testPassword)).thenAnswer((_) async => right(testUser));

        // Act
        await command(email: testEmail, password: testPassword);

        // Assert
        verify(() => mockAuthService.loginWithEmail(testEmail, testPassword)).called(1);
        verifyNoMoreInteractions(mockAuthService);
      });
    });
  });
}

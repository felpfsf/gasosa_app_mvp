import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/auth/login_with_google_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockObservabilityService extends Mock implements ObservabilityService {}

void main() {
  late MockAuthService mockAuthService;
  late MockObservabilityService mockObservability;
  late LoginWithGoogleUseCase command;

  setUpAll(() {
    registerFallbackValue(const UnexpectedFailure('', null, null));
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockObservability = MockObservabilityService();
    command = LoginWithGoogleUseCase(
      auth: mockAuthService,
      observability: mockObservability,
    );

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

  group('LoginWithGoogleUseCase', () {
    const testUser = AuthUser(
      'google-user-123',
      'Google User',
      'googleuser@gmail.com',
      photoUrl: 'https://lh3.googleusercontent.com/a/photo',
    );

    group('Sucesso', () {
      test('deve retornar Right com AuthUser quando login Google bem-sucedido', () async {
        // Arrange
        when(() => mockAuthService.loginWithGoogle()).thenAnswer((_) async => right(testUser));

        // Act
        final result = await command();

        // Assert
        expect(result, isA<Right<Failure, AuthUser>>());
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) {
            expect(user.id, 'google-user-123');
            expect(user.name, 'Google User');
            expect(user.email, 'googleuser@gmail.com');
            expect(user.photoUrl, 'https://lh3.googleusercontent.com/a/photo');
          },
        );
        verify(() => mockAuthService.loginWithGoogle()).called(1);
      });

      test('deve aceitar usuário sem photoUrl', () async {
        // Arrange
        const userWithoutPhoto = AuthUser('user-456', 'Test User', 'test@gmail.com');
        when(() => mockAuthService.loginWithGoogle()).thenAnswer((_) async => right(userWithoutPhoto));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) {
            expect(user.id, 'user-456');
            expect(user.photoUrl, '');
          },
        );
      });

      test('deve lidar com nomes compostos do Google', () async {
        // Arrange
        const userWithCompoundName = AuthUser(
          'user-789',
          'João Pedro da Silva Santos',
          'joao.pedro@gmail.com',
        );
        when(() => mockAuthService.loginWithGoogle()).thenAnswer((_) async => right(userWithCompoundName));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) => fail('Não deveria retornar failure'),
          (user) => expect(user.name, 'João Pedro da Silva Santos'),
        );
      });
    });

    group('Falhas de Autenticação', () {
      test('deve retornar Left com UnexpectedFailure quando usuário cancela login', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Usuário cancelou o login', null, null)));

        // Act
        final result = await command();

        // Assert
        expect(result, isA<Left<Failure, AuthUser>>());
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Usuário cancelou o login');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
        verify(() => mockAuthService.loginWithGoogle()).called(1);
      });

      test('deve retornar Left com UnexpectedFailure quando conta Google não autorizada', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Conta Google não autorizada', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Conta Google não autorizada');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando conta Google desabilitada', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Conta desabilitada', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) => expect(failure.message, 'Conta desabilitada'),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando Google Sign-In falha', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Erro no Google Sign-In', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Erro no Google Sign-In');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando permissões negadas', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Permissões negadas', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) => expect(failure.message, 'Permissões negadas'),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Falhas de Sistema', () {
      test('deve retornar Left com UnexpectedFailure quando sem conexão', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Sem conexão com a internet', null, null)));

        // Act
        final result = await command();

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

      test('deve retornar Left com UnexpectedFailure quando timeout', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Timeout na requisição', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Timeout na requisição');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando servidores Google indisponíveis', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Servidores Google indisponíveis', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) => expect(failure.message, 'Servidores Google indisponíveis'),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve retornar Left com UnexpectedFailure quando erro inesperado', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Erro inesperado no login Google', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<UnexpectedFailure>());
            expect(failure.message, 'Erro inesperado no login Google');
          },
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });

    group('Comportamento e Isolamento', () {
      test('deve chamar AuthService apenas uma vez', () async {
        // Arrange
        when(() => mockAuthService.loginWithGoogle()).thenAnswer((_) async => right(testUser));

        // Act
        await command();

        // Assert
        verify(() => mockAuthService.loginWithGoogle()).called(1);
        verifyNoMoreInteractions(mockAuthService);
      });

      test('deve ser independente entre múltiplas chamadas', () async {
        // Arrange
        when(() => mockAuthService.loginWithGoogle()).thenAnswer((_) async => right(testUser));

        // Act
        await command();
        await command();

        // Assert
        verify(() => mockAuthService.loginWithGoogle()).called(2);
      });

      test('deve permitir chamadas sequenciais com resultados diferentes', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Cancelado', null, null)));

        // Act
        final result1 = await command();

        // Arrange segunda chamada
        when(() => mockAuthService.loginWithGoogle()).thenAnswer((_) async => right(testUser));

        final result2 = await command();

        // Assert
        expect(result1.isLeft, true);
        expect(result2.isRight, true);
      });
    });

    group('Integração com Plataforma', () {
      test('deve lidar com erro de Play Services desatualizado no Android', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('Google Play Services desatualizado', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) => expect(failure.message, contains('Google Play Services')),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });

      test('deve lidar com erro de app não configurado no Firebase', () async {
        // Arrange
        when(
          () => mockAuthService.loginWithGoogle(),
        ).thenAnswer((_) async => left(const UnexpectedFailure('App não configurado no Firebase Console', null, null)));

        // Act
        final result = await command();

        // Assert
        result.fold(
          (failure) => expect(failure.message, contains('Firebase')),
          (user) => fail('Não deveria retornar sucesso'),
        );
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/auth/update_display_name_use_case.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockObservabilityService mockObservability;
  late UpdateDisplayNameUseCase useCase;

  const tUser = AuthUser('user-123', 'João', 'joao@email.com');
  const tFailure = UnexpectedFailure('Erro Firebase', null, null);

  setUpAll(() {
    registerFallbackValue(const UnexpectedFailure('', null, null));
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockObservability = MockObservabilityService();

    useCase = UpdateDisplayNameUseCase(
      auth: mockAuthService,
      observability: mockObservability,
    );

    when(() => mockObservability.logEvent(any(), parameters: any(named: 'parameters'))).thenAnswer((_) async {});
    when(
      () => mockObservability.logError(
        any(),
        stackTrace: any(named: 'stackTrace'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
  });

  group('UpdateDisplayNameUseCase -', () {
    group('sucesso', () {
      setUp(() {
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockAuthService.updateDisplayName(any())).thenAnswer((_) async => right(null));
      });

      test('retorna Right quando nome válido', () async {
        final result = await useCase('Maria');

        expect(result, isRight());
      });

      test('passa nome com trim para o AuthService', () async {
        await useCase('  Maria  ');

        verify(() => mockAuthService.updateDisplayName('Maria')).called(1);
      });

      test('registra evento de sucesso', () async {
        await useCase('Maria');

        verify(() => mockObservability.logEvent('update_display_name_success')).called(1);
      });
    });

    group('validação - nome vazio', () {
      test('retorna Left com mensagem de erro quando nome em branco', () async {
        final result = await useCase('');

        expect(result, isLeft());
        expect(leftFailure(result).message, ProfileStrings.errorNameEmpty);
      });

      test('retorna Left quando nome é só espaços', () async {
        final result = await useCase('   ');

        expect(result, isLeft());
        expect(leftFailure(result).message, ProfileStrings.errorNameEmpty);
      });

      test('não chama AuthService quando nome vazio', () async {
        await useCase('');

        verifyNever(() => mockAuthService.updateDisplayName(any()));
      });
    });

    group('validação - nome muito longo', () {
      test('retorna Left quando nome excede 50 caracteres', () async {
        final longName = 'A' * 51;
        final result = await useCase(longName);

        expect(result, isLeft());
        expect(leftFailure(result).message, ProfileStrings.errorNameTooLong);
      });

      test('aceita nome com exatamente 50 caracteres', () async {
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockAuthService.updateDisplayName(any())).thenAnswer((_) async => right(null));

        final exactName = 'A' * 50;
        final result = await useCase(exactName);

        expect(result, isRight());
      });

      test('não chama AuthService quando nome muito longo', () async {
        final longName = 'A' * 51;
        await useCase(longName);

        verifyNever(() => mockAuthService.updateDisplayName(any()));
      });
    });

    group('usuário não autenticado', () {
      setUp(() {
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => null);
      });

      test('retorna Left sem chamar updateDisplayName', () async {
        final result = await useCase('Maria');

        expect(result, isLeft());
        verifyNever(() => mockAuthService.updateDisplayName(any()));
      });
    });

    group('falha no Firebase', () {
      setUp(() {
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => tUser);
        when(() => mockAuthService.updateDisplayName(any())).thenAnswer((_) async => left(tFailure));
      });

      test('retorna Left com a falha do Firebase', () async {
        final result = await useCase('Maria');

        expect(result, isLeft());
        expect(leftFailure(result).message, tFailure.message);
      });

      test('registra erro de observabilidade', () async {
        await useCase('Maria');

        verify(
          () => mockObservability.logError(
            any(),
            stackTrace: any(named: 'stackTrace'),
            context: {'action': 'update_display_name'},
          ),
        ).called(1);
      });

      test('registra evento de falha', () async {
        await useCase('Maria');

        verify(() => mockObservability.logEvent('update_display_name_failure')).called(1);
      });
    });
  });
}

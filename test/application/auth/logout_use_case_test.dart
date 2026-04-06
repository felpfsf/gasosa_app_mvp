import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/auth/logout_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockObservabilityService mockObservability;
  late LogoutUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const UnexpectedFailure('', null, null));
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockObservability = MockObservabilityService();
    useCase = LogoutUseCase(
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
    when(() => mockObservability.clearContext()).thenReturn(null);
  });

  group('LogoutUseCase -', () {
    group('logout com sucesso', () {
      test('retorna Right quando logout é bem-sucedido', () async {
        when(() => mockAuthService.logout()).thenAnswer((_) async => right(null));

        final result = await useCase();

        expect(result, isRight());
        verify(() => mockAuthService.logout()).called(1);
      });

      test('delega chamada ao AuthService', () async {
        when(() => mockAuthService.logout()).thenAnswer((_) async => right(null));

        await useCase();

        verify(() => mockAuthService.logout()).called(1);
      });
    });

    group('logout com falha', () {
      test('retorna Left quando AuthService falha', () async {
        const failure = UnexpectedFailure('Erro ao fazer logout', null, null);
        when(() => mockAuthService.logout()).thenAnswer((_) async => left(failure));

        final result = await useCase();

        expect(result, isLeft());
        expect(leftFailure(result).message, 'Erro ao fazer logout');
      });
    });
  });
}

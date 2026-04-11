import 'package:flutter_test/flutter_test.dart';
import 'package:gasosa_app/application/auth/delete_account_use_case.dart';
import 'package:gasosa_app/core/either/either.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/domain/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockVehicleRepository mockVehicleRepository;
  late MockObservabilityService mockObservability;
  late DeleteAccountUseCase useCase;

  const tUser = AuthUser('user-123', 'João', 'joao@email.com');
  const tFailure = UnexpectedFailure('Erro inesperado', null, null);
  const tDbFailure = DatabaseFailure('Erro ao deletar dados do usuário', null, null);

  setUpAll(() {
    registerFallbackValue(const UnexpectedFailure('', null, null));
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockVehicleRepository = MockVehicleRepository();
    mockObservability = MockObservabilityService();

    useCase = DeleteAccountUseCase(
      auth: mockAuthService,
      vehicleRepository: mockVehicleRepository,
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

  group('DeleteAccountUseCase -', () {
    group('sucesso', () {
      setUp(() {
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => tUser);
        when(
          () => mockVehicleRepository.deleteAllByUserId(any()),
        ).thenAnswer((_) async => right(unit));
        when(() => mockAuthService.deleteAccount()).thenAnswer((_) async => right(null));
      });

      test('retorna Right quando tudo ocorre com sucesso', () async {
        final result = await useCase();

        expect(result, isRight());
      });

      test('deleta dados locais com o userId correto', () async {
        await useCase();

        verify(() => mockVehicleRepository.deleteAllByUserId('user-123')).called(1);
      });

      test('deleta conta no Firebase após dados locais', () async {
        await useCase();

        verifyInOrder([
          () => mockVehicleRepository.deleteAllByUserId(any()),
          () => mockAuthService.deleteAccount(),
        ]);
      });

      test('limpa contexto de observabilidade após sucesso', () async {
        await useCase();

        verify(() => mockObservability.clearContext()).called(1);
      });

      test('registra evento de sucesso', () async {
        await useCase();

        verify(() => mockObservability.logEvent('delete_account_success')).called(1);
      });
    });

    group('usuário não autenticado', () {
      test('retorna Left sem chamar repositório nem Firebase', () async {
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => null);

        final result = await useCase();

        expect(result, isLeft());
        verifyNever(() => mockVehicleRepository.deleteAllByUserId(any()));
        verifyNever(() => mockAuthService.deleteAccount());
      });
    });

    group('falha ao deletar dados locais', () {
      setUp(() {
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => tUser);
        when(
          () => mockVehicleRepository.deleteAllByUserId(any()),
        ).thenAnswer((_) async => left(tDbFailure));
      });

      test('retorna Left com a falha do repositório', () async {
        final result = await useCase();

        expect(result, isLeft());
        expect(leftFailure(result).message, tDbFailure.message);
      });

      test('não chama deleteAccount no Firebase quando dados locais falham', () async {
        await useCase();

        verifyNever(() => mockAuthService.deleteAccount());
      });

      test('registra erro de observabilidade', () async {
        await useCase();

        verify(
          () => mockObservability.logError(
            any(),
            context: any(named: 'context'),
          ),
        ).called(1);
      });
    });

    group('falha ao deletar conta no Firebase', () {
      setUp(() {
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => tUser);
        when(
          () => mockVehicleRepository.deleteAllByUserId(any()),
        ).thenAnswer((_) async => right(unit));
        when(() => mockAuthService.deleteAccount()).thenAnswer((_) async => left(tFailure));
      });

      test('retorna Left com a falha do Firebase', () async {
        final result = await useCase();

        expect(result, isLeft());
        expect(leftFailure(result).message, tFailure.message);
      });

      test('registra evento de falha', () async {
        await useCase();

        verify(() => mockObservability.logEvent('delete_account_failure')).called(1);
      });

      test('não limpa contexto quando Firebase falha', () async {
        await useCase();

        verifyNever(() => mockObservability.clearContext());
      });
    });

    group('falha por reautenticação necessária', () {
      test('retorna Left com mensagem de reautenticação', () async {
        const reauthFailure = UnexpectedFailure(
          'Por segurança, saia e entre novamente antes de excluir a conta.',
          null,
          null,
        );
        when(() => mockAuthService.currentUser()).thenAnswer((_) async => tUser);
        when(
          () => mockVehicleRepository.deleteAllByUserId(any()),
        ).thenAnswer((_) async => right(unit));
        when(() => mockAuthService.deleteAccount()).thenAnswer((_) async => left(reauthFailure));

        final result = await useCase();

        expect(result, isLeft());
        expect(
          leftFailure(result).message,
          'Por segurança, saia e entre novamente antes de excluir a conta.',
        );
      });
    });
  });
}
